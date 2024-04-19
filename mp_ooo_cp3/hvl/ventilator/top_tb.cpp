#define TOPLEVEL verilator_tb

#include <stdlib.h>
#include <iostream>
#include <filesystem>
#include <fstream>
#include <cmath>
#include <csignal>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vverilator_tb.h"

#define MAX_SIM_TIME 60000000
#define RUNOFF_TIME  100

#define BURSTS   4
#define BA_WIDTH 2
#define RA_WIDTH 20
#define CA_WIDTH 3
#define TOTAL_W  BA_WIDTH + RA_WIDTH + CA_WIDTH

#define tdflt    20
#define tras     44
#define trc      66
#define twr      15

typedef Vverilator_tb dut_t;
typedef VerilatedVcdC trace_t;

dut_t *dut;
trace_t *m_trace ;

vluint32_t ADDR_MASK = ~(~0 << (BA_WIDTH + RA_WIDTH + CA_WIDTH));

// Need to manually be kept consistent with VL
#define REGS  64

int clock_period=0;
int low_cycle=-1, high_cycle=-1;
vluint64_t sim_time = 0;

int base_addr = 0;

// burst memory stuff
std::map<vluint32_t, vluint64_t> memory_array;
int active_row[2<<BA_WIDTH], ras[2<<BA_WIDTH],
  rc[2<<BA_WIDTH], rrd;

vluint64_t mask_off(vluint64_t in, int offset, int width)
{
  vluint64_t mask = ~(~0 << width);
  return (in >> offset) & mask;
}

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

  while (getline(prgm, line))
    {
      memory_array[mask_off(base_addr, 3, TOTAL_W)] = std::stoull(line, 0, 16);
      base_addr += 8;
    }

  prgm.close();


  for (int i=0; i<(1 << BA_WIDTH); i++)
    active_row[i] = -1;
}

void eval_mem()
{
  // idle, read, write
  static int state = 0;
  static int stage = -1;
  static int ctr   = 0;
  static int burst = 0;

  if (dut->clk==1)
    return;

  dut->bmem_resp = 0;
  dut->bmem_rdata = 0;

  int bank_addr  = mask_off(dut->bmem_address, 3+CA_WIDTH, BA_WIDTH);
  int row_addr   = mask_off(dut->bmem_address, 3+CA_WIDTH+BA_WIDTH, RA_WIDTH);
  int total_addr = mask_off(dut->bmem_address, 3, TOTAL_W);
  
  for (int i=0; i<(1 << BA_WIDTH); i++)
    {
      if (i==bank_addr && stage != -1 && stage != 2)
        continue;
      
      rc[i]  -= std::max(0, rc[i] - clock_period);
      ras[i] -= std::max(0, ras[i]-clock_period);
    }

  if (dut->rst)
    {
      state = 0;
      return;
    }

  // pre-dispatch delay
  int timeslice = clock_period;
  if (stage == 3)
    {
      int passage = std::min(ctr, timeslice);
      ctr       -= passage;
      timeslice -= passage;

      rrd            -= std::min(rrd, timeslice);
      rc[bank_addr]  -= std::min(rc[bank_addr], timeslice);
      ras[bank_addr] -= std::min(ras[bank_addr], timeslice);

      if (ctr==0)
        {
          state = 0;
          stage = -1;
        }
    }

  // dispatch
  if (state == 0)
    {
      if (dut->bmem_read)
        state = 1;
      if (dut->bmem_write)
        state = 2;

      if (active_row[bank_addr] != row_addr)
        stage = active_row[bank_addr] >= 0 ? 0:1;
      else
        stage = 2;

      return;
    }

  // timesliced evaluation
  if (stage == 0)
    {
      if (ras[bank_addr] > 0)
        {
          int passage = std::min(ras[bank_addr], timeslice);

          timeslice      -= passage;
          ras[bank_addr] -= passage;

          rc[bank_addr]  -= std::min(rc[bank_addr], passage);
          rrd            -= std::min(rrd, passage);

          if (ras[bank_addr] == 0)
            ctr = tdflt * 1000;
            
          if (timeslice == 0)
            return;
        }

      int passage = std::min(ctr, timeslice);
      ctr       -= passage;
      timeslice -= passage;

      rrd -= std::min(rrd, passage);
      rc[bank_addr] -= std::min(rrd, passage);

      if (ctr==0)
        stage = 1;

      if (timeslice == 0)
        return;
    }

  if (stage == 1)
    {
      if (ctr==0)
        {
          int constraint = std::max(rrd, rc[bank_addr]);
          int passage    = std::min(constraint, timeslice);

          timeslice      -= passage;
          rrd            -= std::min(passage, rrd);
          rc[bank_addr]  -= std::min(passage, rc[bank_addr]);

          if (rc[bank_addr] == 0 && rrd==0)
            {
              ctr            = tdflt * 1000;
              rrd            = twr;
              rc[bank_addr]  = trc;
              ras[bank_addr] = tras;
            }
            
          if (timeslice == 0)
            return;
        }

      int passage = std::min(ctr, timeslice);

      rrd            -= std::min(rrd, passage);
      rc[bank_addr]  -= std::min(rc[bank_addr], passage);
      ras[bank_addr] -= std::min(ras[bank_addr], passage);

      ctr            -= passage;
      timeslice      -= passage;

      if (ctr<=0)
        {
          stage = 2;
          ctr   = (state==1) ? tdflt : 0;
        }

      if (timeslice == 0)
        return;
    }

  if (stage == 2)
    {
      if (ctr != 0)
        {
          rrd            -= std::min(rrd, timeslice);
          rc[bank_addr]  -= std::min(rc[bank_addr], timeslice);
          ras[bank_addr] -= std::min(ras[bank_addr], timeslice);

          int passage = std::min(ctr, timeslice);
          ctr            -= passage;
        }

      dut->bmem_resp = 1;
      if (state==1)
        {
          if (memory_array.count(total_addr + burst) == 1)
            dut->bmem_rdata = memory_array[total_addr + (burst++)];
          else
            {
              dut->bmem_rdata = 0;
              burst++;
            }
        }
      else if (state == 2)
        memory_array[total_addr + (burst++)] = dut->bmem_wdata;

      if (burst==BURSTS)
        {
          burst = 0;
          if (state == 1)
            {
              stage = -1;
              state = 0;
            }
          else if (state==2)
            stage = 3;
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
  eval_mem();
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

  const std::filesystem::path path = argv[2];
  if (!std::filesystem::exists(path))
    {
      std::cerr << "ERR: Invalid file\n";
      exit(EXIT_FAILURE);
    }

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

  std::cout << "Loading from " << path << std::endl;
  initmem(argv[2]);

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

  wait(dut, m_trace, 5);
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
