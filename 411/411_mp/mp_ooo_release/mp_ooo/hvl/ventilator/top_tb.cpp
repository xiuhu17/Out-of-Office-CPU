#define TOPLEVEL verilator_tb

#include <stdlib.h>
#include <iostream>
#include <fstream>
#include <cmath>
#include <csignal>
#include <queue>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vverilator_tb.h"

#define MAX_SIM_TIME 60000000

#define BURSTS   4
#define BA_WIDTH 4
#define RA_WIDTH 20
#define CA_WIDTH 3
#define TOTAL_W  BA_WIDTH + RA_WIDTH + CA_WIDTH

#define REQUESTS 16
#define BANKS    1<<BA_WIDTH

#define tdflt    20 * 1000
#define tras     44 * 1000
#define trc      66 * 1000
#define twr      15 * 1000

typedef Vverilator_tb dut_t;
typedef VerilatedVcdC trace_t;

dut_t *dut;
trace_t *m_trace;

// Need to manually be kept consistent with VL
#define REGS  64

int clock_period=0;
int low_cycle=-1, high_cycle=-1;
vluint64_t sim_time = 0;

int base_addr = 0;

// burst memory stuff
std::map<vluint32_t, vluint64_t> memory_array;
int active_row[BANKS];

// queues
typedef struct mem_op_t {
  bool valid = false;
  bool read;
  vluint32_t addr;
  vluint64_t wdata[BURSTS];
} mem_op_t;

typedef struct resp_t {
  bool read;
  vluint32_t addr;
  vluint64_t rdata[BURSTS] = {0};
} resp_t;

std::vector<mem_op_t> inq;
std::queue<resp_t> outq;

vluint64_t mask_off(vluint64_t in, int offset, int width)
{
  vluint64_t mask = ~(~0 << width);
  return (in >> offset) & mask;
}

vluint64_t get_bank(vluint64_t in)
{ return mask_off(in, 5+CA_WIDTH, BA_WIDTH); }

vluint64_t get_row(vluint64_t in)
{ return mask_off(in, 5+CA_WIDTH+BA_WIDTH, RA_WIDTH); }

vluint64_t get_addr(vluint64_t in)
{ return mask_off(in, 3, TOTAL_W-1); }

void initmem(char* mempath)
{
  std::ifstream prgm(mempath);
  std::string line;

  // ignore first line
  getline(prgm, line);
  if (line[0]=='@')
    {
      try
        { base_addr = std::stoi(line.substr(1, std::string::npos), 0, 16); }

      catch (const std::exception& e)
        {
          std::cerr << "ERR: Supplied mem file does not supply array offset\n";
          prgm.close();
          exit(EXIT_FAILURE);
        }
    }
  else
    {
      std::cerr << "ERR: Supplied mem file does not supply array offset\n";
      prgm.close();
      exit(EXIT_FAILURE);
    }

  base_addr = mask_off(base_addr, 0, TOTAL_W-1);
  int test_addr = 0x60000020;
  while (getline(prgm, line))
    {
      memory_array[base_addr] = std::stoull(line, 0, 16);
      base_addr++;
    }

  prgm.close();


  for (int i=0; i<(1 << BA_WIDTH); i++)
    active_row[i] = -1;
}


// banked_memory
void eval_mem_new()
{
  static int      stage[BANKS] = {0}; // idle, delay, dispatch, post-dispatch delay
  static mem_op_t active[BANKS];

  static mem_op_t req;
  static int  inp_burst = 0;
  static int  out_burst = 0;

  static int  ctr[BANKS] = {-1};

  static int ras[2<<BA_WIDTH], rc[2<<BA_WIDTH], rrd;

  if (dut->clk == 1)
    return;

  dut->bmem_resp  = 0;
  dut->bmem_rdata = 0;
  dut->rdy        = 1;

  if (dut->rst == 1)
    {
      for (int i=0; i<BANKS; i++)
        {
          stage[i] = 0;
          active[i].valid = false;
          active_row[i] = -1;
          ras[i] = 0;
          rc[i] = 0;
        }
      return;
    }

  // issue requests
  for (int i=0; i<BANKS; i++)
    {
      if (stage[i]==0)
        {
          int enqueued = -1;
          for (int j=0; j<inq.size(); j++)
            if (get_bank(inq[j].addr) == i)
              {
                active[i].valid = true;
                active[i] = inq[j];
                enqueued = j;
                if (get_row(inq[j].addr) == active_row[i])
                  {
                    break; // row hit
                  }
              }
          if (enqueued >= 0)
            {
              inq.erase(inq.begin() + enqueued);
              stage[i] = 1;
              ctr[i]   = -1;
            }
        }
    }

  // enqueue requests from DUT, assert the rdy output
  if (inp_burst > 0)
    {
      req.wdata[inp_burst++] = dut->bmem_wdata;

      if (inp_burst==BURSTS)
        {
          inp_burst = 0;
          inq.push_back(req);
        }
    }
  else if (dut->bmem_read || dut->bmem_write)
    {
      req.valid = 1;
      req.read = dut->bmem_read;
      req.addr = dut->bmem_address;

      if (dut->bmem_write)
        {
          req.wdata[0] = dut->bmem_wdata;
          inp_burst = 1;
        }
      else
        inq.push_back(req);
    }

  if (inq.size() >= REQUESTS)
    dut->rdy = 0;

  // assign output to the interface from queue
  if (outq.size() > 0)
    {
      if (outq.front().read)
        {
          dut->bmem_resp  = 1;
          dut->raddr      = outq.front().addr;
          dut->bmem_rdata = outq.front().rdata[out_burst++];
        }

      if (out_burst == BURSTS || !outq.front().read)
        {
          out_burst = 0;
          outq.pop();
        }
    }

  // evaluate stage 5, shift into the output queue
  for (int i=0; i<BANKS; i++)
    if (stage[i] == 5)
      {
        resp_t resp;
        resp.read  = active[i].read;
        resp.addr  = active[i].addr;

        int total_addr = get_addr(resp.addr);
        if (resp.read)
          {
            for (int k = 0; k<BURSTS; k++)
                if (memory_array.count(total_addr + k) == 1)
                  resp.rdata[k] = memory_array[total_addr + k];
          }
        else
          for (int k = 0; k<BURSTS; k++)
            memory_array[total_addr + k] = active[i].wdata[k];

        outq.push(resp);

        stage[i] = 0;
      }

  int timeslice[BANKS]; // time allocation per bank
  std::fill_n(timeslice, BANKS, clock_period);

  // evaluate stage 1 mem delays
  for (int i=0; i<BANKS; i++)
    {
      if (stage[i]==1)
        {
          if (ctr[i] ==-1) // use stage 1 as a dispatch
            {
              if (get_row(active[i].addr) == active_row[i])
                {
                  stage[i] = 4; // row hit
                  if (active[i].read)
                    ctr[i] = tdflt;
                  else
                    ctr[i] = twr;
                  continue;
                }
              else if (active_row[i]==-1) // row miss, no precharge
                {
                  stage[i] = 2;
                  continue;
                }

              ctr[i] = tdflt;
            }

          if (ras[i] > 0)
            {
              int passage = std::min(ras[i], timeslice[i]);
              timeslice[i] -= passage;

              ras[i]    -= passage;
              rc[i]     -= std::min(rc[i], passage);

              if (timeslice[i] == 0) continue;
            }

          int passage = std::min(ctr[i], timeslice[i]);
          ctr[i] -= passage;
          timeslice[i] -= passage;
          rc[i] -= std::min(passage, rc[i]);


          if (ctr[i] == 0) stage[i] = 2;
        }
    }

  auto timeordering = [timeslice](int a, int b) -> bool {
    return std::max(0, timeslice[a] - rc[a])  > std::max(0, timeslice[b] - rc[b]);
  };

  std::vector<int> indices;
  for (int i=0; i<BANKS; i++)
    indices.push_back(i);
  std::sort(indices.begin(), indices.end(), timeordering);

  int g = -1;
  for (int i=0; i<BANKS; i++)
    if (stage[i] == 2)
      {
        g = i;
        break;
      }

  if (g != -1)
    {
      // stage 2 evaluation - approximate in multi-bank race condition
      // if this is very bad, just rewrite with per-ps evaluation
      int endtime = std::max(0, std::min(clock_period - rrd, timeslice[g] - rc[g]));

      // simulate accurately for g, until end of timeslice for all else
      int diff     = timeslice[g] - endtime;
      rc[g]       -= std::min(diff, rc[g]);
      ras[g]      -= std::min(diff, ras[g]);
      rrd         -= std::min(rrd, clock_period - endtime);
      timeslice[g] = endtime;

      if (rrd == 0 && rc[g] == 0)
        {
          stage[g] = 3;

          rrd = twr - endtime;
          ras[g] = tras;
          rc[g] = trc;

          ctr[g] = tdflt;
        }

      for (int i=0; i<BANKS; i++)
        {
          if (stage[i]==2 && i!=g)
            {
              ras[i] -= std::min(timeslice[i], ras[i]);
              rc[i] -=  std::min(timeslice[i], rc[i]);
              timeslice[i] = 0;
            }
        }
    }
  else
    rrd -= std::min(rrd, clock_period);

  // stage 3 RCD
  for(int i=0; i<BANKS; i++)
    {
      if (stage[i] == 3)
        {
          int passage    = std::min(timeslice[i], ctr[i]);
          ctr[i]        -= passage;
          timeslice[i]  -= passage;

          rc[i]  -= std::min(rc[i], passage);
          ras[i] -= std::min(ras[i], passage);

          if (ctr[i] == 0)
            {
              stage[i] = 4;
              active_row[i] = get_row(active[i].addr);
              if (active[i].read)
                ctr[i] = tdflt;
              else
                ctr[i] = twr;
            }
        }
    }

  // stage 4: CAS delay
  for(int i=0; i<BANKS; i++)
    {
      if (stage[i] == 4)
        {
          ctr[i] -= std::min(timeslice[i], ctr[i]);

          rc[i]  -= std::min(rc[i], timeslice[i]);
          ras[i] -= std::min(ras[i], timeslice[i]);

          // need to wait for next posedge now...
          if (ctr[i] == 0) stage[i] = 5;
        }
    }

  for (int i=0; i<BANKS; i++)
    {
      if (timeslice[i] > 0)
        {
          ras[i] -= std::min(ras[i], timeslice[i]);
          rc[i]  -= std::min(rc[i] , timeslice[i]);
        }
    }
}

void setdefaults(dut_t *dut)
{
  dut->rst        = 0;

  dut->bmem_resp  = 0;
  dut->bmem_rdata = 0;
}

void end(bool failed=false)
{
  if (m_trace != NULL)
    m_trace->close();
  dut->final();
  delete dut;

  std::cout << "RUNTIME: " << sim_time/2 * clock_period << "\n";

  if (failed)
    {
      std::cerr << "SIMULATION FAILED\n";
      exit(EXIT_FAILURE);
    }
  else
    {
      std::cout << "Simulation complete!\n";
      exit(EXIT_SUCCESS);
    }
}

void clocked_assertions()
{
  if (dut->clk==1)
    {
      if (dut -> bmem_read && dut -> bmem_write)
        {
          std::cout << "SIMULTANEOUS R/W\n";
          end(true);
        }
    }
}

void inthandler(int signal_num)
{
  dut->final();
  delete dut;

  std::cerr << "INTERRUPTED - SIMULATION FALED ON CYCLE " << sim_time/2 << std::endl;
  exit(signal_num);
}

void tick(dut_t *dut)
{
  dut->clk ^= 1;
  dut->eval();
  clocked_assertions();
  eval_mem_new();
  if (m_trace != NULL && sim_time/2 >= low_cycle && sim_time/2 <= high_cycle)
    m_trace->dump(sim_time);
  sim_time++;
}

void wait(dut_t *dut, trace_t *m_trace, int cycles)
{
  for (int i=0; i<cycles*2; i++)
    tick(dut);
}

int main(int argc, char** argv, char** env) {
  if (argc != 3 && argc != 5)
    {
      std::cerr << "ERR: Invalid argument count. Got " << argc << ".\n";
      exit(EXIT_FAILURE);
    }

  std::cout << "Starting Verilator Simulation\n";

  if (argc==5)
    {
      try {
        low_cycle = std::stoi(argv[3]);
        high_cycle = std::stoi(argv[4]);
      }

      catch (const std::exception& e)
        {
          std::cerr << "ERR: Invalid cycle bounds" << std::endl;
          exit(EXIT_FAILURE);
        }

      if (low_cycle != -1)
        std::cout << "Logging from " << low_cycle << " to " << high_cycle << std::endl;

      if (high_cycle < low_cycle)
        std::cerr << "ERR: Invalid logging bounds" << std::endl;
    }

  try {
    clock_period = std::stoi(argv[1]);
  }

  catch (const std::exception& e)
    {
      std::cerr << "ERR: Invalid Clock Period" << std::endl;
      exit(EXIT_FAILURE);
    }

  std::cout << "Clock Period set to " << clock_period << "ps\n";

  initmem(argv[2]);
  std::cout << "Loaded memory datae from LST file" << std::endl;

  dut = new dut_t;

  Verilated::traceEverOn(true);
  if (argc==5)
    {
      m_trace = new VerilatedVcdC;
      dut->trace(m_trace, 5);
      m_trace->open("waveform.vcd");
    }
  else
    m_trace = NULL;

  signal(SIGINT, inthandler);

  dut->clk=1; // for verbosity

  setdefaults(dut);
  dut->rst = 1;

  wait(dut, m_trace, 2);
  setdefaults(dut);

  for (int i=0; i<MAX_SIM_TIME; i++)
    {
      wait(dut, m_trace, 1);
      if (dut->halt)
        {
          wait(dut, m_trace, 5);
          end();
        }
      if (dut->error)
        {
          wait(dut, m_trace, 5);
          end(true);
        }
    }

  end();
}
