# ECE 411: mp_cache GUIDE

## Multicycle 4-Way Set-Associative Cache

> The software programs described in this document are confidential
> and proprietary products of Synopsys Corp. or its licensors. The
> terms and conditions governing the sale and licensing of Synopsys
> products are set forth in written agreements between Synopsys Corp.
> and its customers. No representation or other affirmation of fact
> contained in this publication shall be deemed to be a warranty or
> give rise to any liability of Synopsys Corp. whatsoever. Images of
> software programs in use are assumed to be copyright and may not be
> reproduced.
> 
> This document is for informational and instructional purposes only.
> The ECE 411 teaching staff reserves the right to make changes in
> specifications and other information contained in this publication
> without prior notice, and the reader should, in all cases, consult
> the teaching staff to determine whether any changes have been made.

---

**This document, GUIDE.md, serves as a gentle, guided tour of the MP. For
strictly the specification and rubric, see [README.md](./README.md).**

## Cache Design

It is **strongly recommended** that you carefully draw out both the
datapath and the state machine for the cache you will design.
This process will help you identify edge cases in your design and will
make writing the RTL significantly easier and faster. You should go to
office hours and ask your TAs to look over the drawing as well.

If you're having trouble getting started, the course textbook [HP1]
details the design of a similar multicycle cache in "Chapter 5: Large
and Fast: Exploiting Memory Hierarchy". You will need certain changes
to the finite state machine due to the behavior of our SRAM model,
detailed below.
We highly encourage you to use the textbook as a guide while doing
this MP, especially to understand conceptually how cache
microarchitectures are designed. At the same time, please do not
blindly copy logic from the textbook, since in certain cases our
models and simulations differ from the assumptions in [HP1]. Once you
read the textbook, draw your implementation of the cache by looking at
the provided Verilog models.

## Verification

We have provided a skeleton testbench in `cache_dut_tb.sv` for testing
your cache. You will need to complete this testbench to verify that
your cache works. Similar to `mp_verif`, it has `TODOs` in the code
for you to complete. You should refer back to the testbenches in
`mp_verif` to get an idea of how to cleanly organize your testbench so
that you can exercise edge cases.

### Loading files into `simple_memory.sv`

The provided memory model loads a memory file using `$readmemh` from
`mp_cache/sim/sim/memory.lst`. You should populate this file with the
memory contents that you want to test. The format of this file is
specified in IEEE 1800-2017 (the SystemVerilog specification), in the
section "21.4 Loading memory array data from a file". 
Alternately, you can modify `simple_memory.sv` to have random data
using SystemVerilog's randomization features.

### Constrained Random
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

### Coverage

Setting up a simple covergroup can be extremely easy, and will help
pinpoint bugs such as not using a certain way or not entering a
certain FSM state. You don't need to put the covergroup in a class,
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

## SRAM and OpenRAM

### What is SRAM?
In the past, to generate small memories, you have used a simple array
of flip flops (for example, in the `mp_pipeline` register file). Such
a design does not scale for large memories like your cache data and
tag arrays. SRAMs offer better power and area outcomes for the design
as compared to flip flop based implementations via manual optimization
to provide the best density and timing on the provided technology.

The SRAM block we use is a hard IP. Hard IPs are generally IP blocks
that come as a package of both a simulation model and the physical
design file. The simulation model can be used during the RTL phase for
verification. Note that the simulation models are typically not
synthesizable, they are merely Verilog files that mimic the behavior
of the IP. The physical design part will be integrated in a later step
of the design flow, where the layout is directly copy and pasted into
your final mask-level design.

### What is OpenRAM?
The tool we use to generate SRAM IPs is known as a memory
compiler. For ECE 411, we use the OpenRAM memory compiler.
The important files that will be generated includes:
- The Verilog file used by VCS as a stub for simulation.
- The `.db` file used by DC for timing information and area
  estimation.
- The GDS file, which is the physical design file. It is not used
  in this class.

To use OpenRAM, first prepare a config file in `sram/config`.
We have provided the SRAM config file you should use for this MP.
All available options can be found listed in
`/class/ece411/OpenRAM/compiler/options.py`.

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
  write. You can have it permanently asserted for this MP.

- `web`: Active low write enable, assert for writing and deassert for
  reading.

- `addr`: The address.

- `din`: Write data.

- `dout`: Read data.

You can find the timing diagram in README.md.

You might have noticed that the timing diagrams for the SRAM contain
"old" values for write addresses. This is called a non-write-through
SRAM, or read-first SRAM. During a write, the read port will still
spit out some value. For non-write-through SRAM, this value is the old
value stored in the memory array. For write-through (or sometimes
called write-first) SRAM, this will be the newly written value.
You need to keep this non-write-though property in mind when designing
your state machine.

A note about the SRAM Verilog model: we have heavily modified the
generator to produce modern Verilog in a style that is commonly used,
and changed some properties so that it will fit our narrative. This is
a significant departure from OpenRAM's default behavior. If you are
unfortunate enough that you need to use OpenRAM in the future after
this class, please keep this modification in mind.
