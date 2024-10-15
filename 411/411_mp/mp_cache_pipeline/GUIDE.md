# ECE 411: mp_cache GUIDE

## Pipelined 4-Way Set-Associative Cache

**This document, GUIDE.md, serves as a gentle, guided tour of the MP. For
strictly the specification and rubric, see [README.md](./README.md).**

# Cache Design

## Plan Ahead

It is **strongly recommended** that you carefully draw out the
datapath for the cache you will design.
This process will help you identify edge cases in your design and will
make writing the RTL significantly easier and faster. You should go to
office hours and ask your TAs to look over the drawing as well.

## Architecture

If you're having trouble getting started, the course textbook [HP1]
details the design of a state-machined cache in "Chapter 5: Large
and Fast: Exploiting Memory Hierarchy". Even though we are designing
pipelined cache in this MP, most of the principles are interchangeable.

For the state-machined design, the entire design serves one request at a time,
which is the source of inefficiency. All control signals come from the explicit
state machine which dictates the current status of the cache.

![pipeline_stage](./doc/images/pipeline_stage.svg)

For the pipelined version, while the current request has been registered on
the pipeline register (including the register in SRAM) and been processed,
another request is already lined up on the input of the pipeline register. This way,
you will get the ideal throughput of 1 .There is still "state" in this pipelined
cache, however, it is now implicitly encoded, and control signals will come from
doing logic on these states. Say for example, the condition for writing back is:
if the current status on the right hand side stage says it is a miss and dirty. While
waiting for DFP to finish, you of course want to stall the pipeline. Once the write
back is done, you can now change the "state" by marking this line as clean.
Now the combinational logic will realize that this is a clean miss. It will continue to stall,
and start fetching the line. After DFP response, you will update the state by writing the new line
into the data array, and update the tag, and of course valid and dirty bits. On the next cycle,
everything will now look like a hit.

## Handling Write

You may have noticed that our requirements on writes for a "pipelined cache" are somewhat weak:
we only require a throughput of 0.5 writes/cycle. Although it's technically possible to get
a write throughput closer to 1 write/cycle, this requirement is at 0.5 writes/cycle to make implementation
(and verification) as simple as possible. You are required to simply stall after every write hit
to ensure that the write completed into SRAM, and any transaction with the cache afterwards
(ex. read hit) has intuitive latencies.

# Verification

We have provided a skeleton testbench in `top_tb.sv` for testing
your cache. You will need to complete this testbench to verify that
your cache works. Similar to `mp_verif`, it has `TODOs` in the code
for you to complete. You should refer back to the testbenches in
`mp_verif` to get an idea of how to cleanly organize your testbench so
that you can exercise edge cases.

## Loading files into `simple_memory_256_wo_mask.sv`

The provided memory model loads a memory file using `$readmemh` from
a file specified on the Makefile command line. This file should be in
the same format as those you see in previous MPs. The specification
for this format can be found in IEEE 1800-2017 (the SystemVerilog specification)
Section 21.4. You should write your own memory file with contents of your choice.
Alternately, you can modify `simple_memory_256_wo_mask.sv` to have random data using
SystemVerilog's randomization features.

Lets say you wrote your memory file in `testcode/memory.lst`. In `sim`:

```bash
make run_vcs_top_tb MEM=../testcode/memory.lst
```

## Constrained Random
Caches present another nice application of constrained random vector
generation: generating addresses that exercise certain cases. For
instance, to verify your PLRU logic, you would like to generate
addresses that have the same index bits, but have randomized tags and
offsets. For example:

```systemverilog
std::randomize(addr) with {addr[8:5] == 4'hf;};
```

This will generate addresses that belongs to set `15`. Note that you
don't in general need classes for constrained randomness, you can do
it inline using `std::randomize()`.

## Coverage

Setting up a simple covergroup can be extremely easy, and will help
pinpoint bugs such as not using a certain way or not entering a
certain state. You don't need to put the covergroup in a class,
and you can automate the sampling by triggering it at every clock,
like this:

```systemverilog
covergroup cg @(posedge clk);
    all_fsm_states           : coverpoint dut.control.state iff (!rst);
    writeback_to_pmem        : coverpoint dut.dfp_write {bins assert_write = {1};}
    read_all_cachelines_way0 : coverpoint dut.datapath.way0.addr iff (dut.ufp_rmask != '0);
endgroup : cg
```

Note the use of hierarchical references to make sampling easy. You can
extend this covergroup to track PLRU state, various state transitions,
and address space coverage.

# SRAM and OpenRAM

## What is SRAM?
In the past, to generate small memories, you have used a simple array
of flip flops (for example, in the `mp_pipeline` register file). Such
a design does not scale for large memories like your cache data and
tag arrays. SRAMs offer better power area, and timing outcomes for the design
as compared to flip flop based implementations via manual optimization
to provide the best density and timing on the provided technology.

The SRAM block is a hard IP. Hard IPs are generally IP blocks
that come as a package of both a simulation model and the physical
design file. The simulation model can be used during the RTL phase for
verification. Note that the simulation models are typically not
synthesizable, they are merely Verilog files that mimic the behavior
of the IP. The physical design part will be integrated in a later step
of the design flow, where the layout is directly copy and pasted into
your final mask-level design.

## What is OpenRAM?
The tool we use to generate SRAM IPs is known as a memory
compiler. For ECE 411, we use the OpenRAM memory compiler.
The important files that will be generated includes:
- The Verilog file used by VCS as a stub for simulation.
- The `.db` file used by DC for timing information and area
  estimation.
- The GDS file, which is the physical design file. It is not used
  in this class.

To use OpenRAM, first prepare a config file in `sram/config`.
We have provided the SRAM config file you need use for this MP.
Scripts in the provided file will convert them into actual
configuration file used by OpenRAM.

Then, in `sram`, run:

```bash
$ make
```

This will generate all relevant files in `sram/output`. The Makefile
also converts the timing model to a format that DC can use. This
timing model is used by the provided synthesis script.

Here is the list of signals for the SRAM blocks:
- `clk`: The clock.

- `csb`: Active low chip select, assert this when you need to read or
  write.

- `web`: Active low write enable, assert for writing and deassert for
  reading.

- `wmask`: Active high write enable for each byte. Will be ignored if
  `web` is deasserted.

- `addr`: The address.

- `din`: Write data.

- `dout`: Read data.

You can find the timing diagram in README.md.

Generic SRAM like these does not have a deterministic power-on value, nor does
it have a reset pin. This is the reason why we require you to use
flip-flop base array for valid and PLRU array.

You might have noticed that the timing diagrams for the SRAM contain
"old" values for write addresses. This is called a non-write-through
SRAM, or read-first SRAM. During a write, the read port will still
spit out some value. For non-write-through SRAM, this value is the old
value stored in the memory array. For write-through (or sometimes
called write-first) SRAM, this will be the newly written value.
You need to keep this non-write-though property in mind when designing
your cache.

A note about the SRAM Verilog model: we have heavily modified the
generator to produce modern Verilog in a style that is commonly used,
and changed some properties so that it will fit our narrative. This is
a significant departure from OpenRAM's default behavior. If you are
unfortunate enough that you need to use OpenRAM in the future after
this class, please keep this modification in mind.
