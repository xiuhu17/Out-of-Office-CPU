# ECE 411: mp_pipeline GUIDE

## Pipelined RV32I Processor

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

## Getting Started
The intended CPU functionality will be similar to the CPU provided in Part 4 of `mp_verif`,
since they implement the same instruction set. We encourage you
to copy over any parts of that provided code you deem re-useable.

We recommend partitioning your design into multiple modules across many files
to keep your code readable. We highly suggest separating each pipeline
stage into their own module and to connect them together in `cpu.sv`.

We highly recommend using a struct for your pipeline stage registers.
We have provided some starter code in `pkg.sv`.
In your `cpu.sv`, we suggest you do something like this:

```SystemVerilog
if_id_t if_id_reg, if_id_reg_next;

always_ff @(posedge clk) begin
  if_id_reg <= if_id_reg_next;
  // ...
end

id_stage id_stage_i (
  .if_id(if_id_reg),
  .id_ex(id_ex_reg_next)
);
```

## The RV32I ISA
If you are unsure about what a specific instruction does,
it might be a good idea to check what the CPU in `mp_verif` does to execute that instruction.

In addition to Chapter 2 and Chapter 19, you should also familiarize yourself with
the RISC-V ISA from a programmer's perspective.
This includes assembler mnemonics and pseudo-instructions (such as `nop`) which will prove useful
when writing testcode and/or disassembling binaries. Refer to **Chapter 20** for more details.

## More on Design Specification

### Access Alignment
According to Section 2.6 of the RISC-V specification, a processor should include support for misaligned memory access.
However, for this MP, we will relax the requirement: you only need to support naturally aligned load and stores.
Simply put, this means that for an *n* byte piece of data, it is guaranteed that the address of the data mod *n* is 0.
In conjunction with the fact that the biggest datatype in RV32I is 32-bit integers, the consequence of this
is that all pieces of data will be contained within a single, 4-byte aligned word.

Non-naturally aligned memory accesses will not be tested. As a result, you do not need to implement trap logic.

When interacting with memory, you should always use 4-byte aligned addresses as outputs to `imem_addr` and `dmem_addr`.
To specify which part of the 4 bytes to access, use the `w/rmask`. Each `1` bit in the `w/rmask` indicates the validity
of the respective byte in the 4-byte word. A non-zero `w/rmask` indicates a write/read request to the memory.

For example, if your processor were to access the byte at address `0x10000003`, your processor should access `0x10000000`
and set `w/rmask` to `4'b1000`.

### Branch Prediction
In order to avoid excessive stalls in a pipelined processor, a branch predictor is necessary. This is because after
fetching a branch instruction, you would like to continue fetching the next instruction in the following cycle.
However, since the branch instruction will not yet have resolved, your CPU will instead need to make a *prediction*
about which address is correct. For this MP, you may simply use a static-not-taken branch predictor.
This predictor always assumes branches will not be taken, i.e. your fetch stage will always fetch the next instruction (`pc`+4) and flush the
erroneously fetched instructions if the branch is resolved to be taken.

#### Forwarding
We recommend you refer to the lectures or the textbook (Computer Organization and Design the Hardware/Software Interface RISC-V edition by Patterson & Hennessy in section 4.7), where this topic is discussed in detail.

#### Flushing
Since the branch predictor cannot guarantee a correct prediction, you may have invalid instructions fetched/executed
after a branch instruction. Therefore, when a branch misprediction is detected, your processor must flush any instructions
present in the pipeline to prevent them from affecting the correctness of your CPU's execution.

You can do so either by having a valid bit in your pipeline register, and setting this to invalid on a flush,
or by changing the signals that will modify the architectural state to something where they would not.

#### Stalling
Not every stage in the pipeline takes exactly one cycle. The instruction fetch and memory stages both must wait for
memory to respond before their work is completed, which may take multiple cycles. This will require your processor to
stall.

You may choose to stall your entire processor when encountering a stall signal, or only stall the current stage and any stage before it.

## Verification
You can use the same methods used in `mp_verif` to verify your CPU.

You can use the two provided memory models and load RISC-V programs into your design.
Then you may use Spike to generate the golden trace for your program.

You can also use the random testbench from your `mp_verif` to test your CPU.

You must use RVFI to help check the correctness of your processor. 


## Synthesis
We synthesize the design using Synopsys Design Compiler. To synthesize your design, inside the `synth` folder run:
```
$ make synth
```
If your design is successfully synthesized, this will produce an area report and a timing report at `reports/area.rpt` and `reports/timing.rpt` respectively.

## Lint
We use Spyglass to check for potential issues with your design. To run the linter, inside the `lint` folder run:
```
$ make lint
```
Read `reports/lint.rpt` for the output.

## RVFI
It is mandatory for your RVFI to be working for every checkpoint. RVFI is a handy tool that will
snoop the commits of your processor, and check with the spec to see if your processor has any errors.
It essentially runs another RISC-V core parallel to yours and crosschecks that your commits are correct. 

The RVFI file is at `hvl/rvfimon.v`. You need to give it the correct signals by modifying
`hvl/rvfi_reference.json`. To get started, you could look at this: https://github.com/SymbioticEDA/riscv-formal/blob/master/docs/rvfi.md

In order to protect the hvl files, you will assign the hierarchical connection in `hvl/rvfi_reference.json`.
A Python script will sanitize this file and generate a `.svh` file, sourced in `top_tb.sv:41`.
Your hierarchical reference should start with `dut`, as specified in `top_tb.sv:24`.

- What is a hierarchical reference? Consider the circuit used in Part 2.2 (`comb_loop`) of `mp_verif`.
  If we want to refer to the `internal_counter` logic variable in module `a` starting from the top
  level design in the HVL testbench, we could do the following:
  `dut.a.internal_counter`. This is a hierarchical reference. Note that the reference names use the
  *name of the module instantiation* and not the *name of the module*. Specifically, we use `dut` instead of `top`.

**Never use hierarchical reference in your hdl!**
The usage of hierarchical references in HDL is **strictly forbidden** in ECE411. Their usage is only permitted in 
`hvl/rvfi_reference.json` and other HVL files. If you find yourself tending towards hierarchical references in HDL,
you most likely need to add another port to your module.

A few notable signals:

- `valid`: Signify to RVFI that there is a new instruction that needs to be commited.
  Should be high for one and only one cycle for each instruction.
- `order`: The serial number of the instruction. This number should start from 0 and
  increase by one on each commit. We highly suggest you assign each instruction with
  this serial number in the fetch stage.

All the signals going to RVFI should be from your write-back stage, corresponding to the
current instruction being committed. You should pass all this information down the pipeline.
You do not have to worry about wasting area on data which the write-back stage does not need,
since the synthesis tool will optimize them out.

Provided you have connected your RVFI correctly and piped your signals along
your processor correctly, here are some common RVFI errors you might see:
- ROB error: This means that your `order`/`valid` has some issue. Check if your `order` starts at 0, or if you have some ID that was skipped or committed more than once.
- Shadow PC error: Likely your processor went on a wrong path, usually by an erroneous jump/branch.
- Shadow RS1/RS2 error: Likely a forwarding issue.
- RD error: Likely the ALU calculation is wrong.

## Loading programs into your design
To load a program into your design, we need to generate a memory initialization file, `memory.lst`,
that is placed into the simulation directory `mp_pipeline/sim`. The `generate_memory_file.sh` script
located in the `mp_pipeline/bin` directory is used to do this.

The `generate_memory_file.sh` script takes a RISC-V assembly file or a single C file as input,
optionally compiles it to assembly, assembles it into a RISC-V ELF then an object file, and converts
the object file into a suitable format for initializing the testbench memory.

The `generate_memory_file.sh` script stores all its intermediate products in `mp_pipeline/sim/bin`.
Notably, it places the ELF version of your program there, which can be directly fed to Spike.
You can also find the disassembly in there, which will become very useful when debugging your design.

The `generate_memory_file.sh` script is part of the Makefile and gets executed automatically every time you make `run_top_tb PROG=...`

In your own testcode, include one of the following 3 code segments as the last instructions. This acts as a flag to terminate the Spike simulation.
Without this, Spike will continue to run infinitely until it generates a log that causes you to exceed your EWS disk quota or until you manually stop
the simulation with `Ctrl+C`:

```gas
slti x0, x0, -256

halt1:
  j halt1

halt2:
  beqz x0, halt2
```

## Spike
Spike is the golden software model for RISC-V. You can give it a RISC-V ELF file, and it will run it for you.
You can also interactively step through instructions, look at all architectural states and also memory in it.
However, it is likely that you do not need these features for this MP.
You would likely only want it to give you the golden trace for your program.

The compile script in `mp_pipeline/bin` will generate ELF file in `mp_pipeline/sim/bin`

To run an ELF on spike, run the following command
```
$ make spike ELF=PATH_TO_ELF
```
Replace PATH_TO_ELF with path to an ELF file Then you can find the golden Spike log in `mp_pipeline/sim/spike.log`

In addition, code provided in `mp_pipeline/hvl/top_tb.sv` will print out a log in the exact same format,
which can be found at `mp_pipeline/sim/sim/commit.log`. You can use your favorite diff tool to compare the two.

We have modified Spike so that it will terminate on any of the three magic termination instructions listed in the previous section.

Spike uses `x5`, `x10`, and `x11` for some internal purposes before it jumps to run the ELF you supplied.
Keep this in mind when you are writing your own test code.

## Interpreting the Spike Log
Here is the example assembly code we will run through Spike to analyze its log (omitting other 
details like labels, alignment, and Spike terminating code).
```
auipc x2, 40
sw x1, 0(x2)
lh x1, 0(x2)
```

The output Spike commit log file will look like this.
```
core   0: 3 0x80000000 (0x00028117) x2  0x80028000
core   0: 3 0x80000004 (0x00112023) mem 0x80028000 0x00000000
core   0: 3 0x80000008 (0x00011083) x1  0x00000000 mem 0x80028000
```


It's just a bunch of numbers! How do we interpret this? First, each line of the file is a single committed instruction from the processor.
The instructions are listed in the exact order they were commited from the processor. Now, let's focus on the first line 
and work our way left to right to understand what a single line tells about one instruction.
```
core   0: 3 0x80000000 (0x00028117) x2  0x80028000
```

First, we have `core   0:`. This indicates that this instruction was executed on core 0 of the simulated Spike processor.
Our setup of Spike is configured as a uniprocessor (one core), so all instructions will be executed by `core 0`. We are also only concerned with uniprocessors for the MPs in ECE411, so **this is a field you can ignore in your ECE411 debugging context.**

Second, we have `3`. A slight tangent is needed to understand this one. The RISC-V architecture
can be implemented to consider different levels of privilege levels for programs that permit
various levels of hardware resource access. This `3` indicates this code is executing in the 
most privileged "machine mode" level. We do not consider privilege levels at all in
these MPs, so **this is another field that you can ignore when debugging**.

Third, we have `0x80000000`. This indicates the PC value of this instruction i.e. the memory
address from where we fetched this instruction from.

Fourth, we have `0x00028117`. This is hex representation of the executed instruction i.e. the 
contents of the memory at the address specified by the previous field/the PC. It is often 
helpful to encode this to its respective assembly format which can done easily by pasting this 
field into this site: https://luplab.gitlab.io/rvcodecjs/. In this specific example, we can
confirm that this instruction is `auipc x2, 40` which matches our assembly code.

The next fields vary in format depending on the executed instruction as illustrated in the 
above Spike log example. In general, this section denotes a change to the architectural state
of the processor. This can take form as modifying the value of a register via a value calculated
internal to the processor, modifying the value of a register via a load from a certain memory 
address, or modifying the contents of memory at a certain address via a store.

As we previously decoded, the first instruction is `auipc x2, 40`, which writes the current PC 
value plus the specified immediate into register x2. We  saw from the third section that PC
was `0x80000000` and the immediate is (d40 << 12) = (h28 << 12)  = `00028000` leading us to load
`0x80000000` + `00028000` = `0x80028000` into x2 as indicated by `x2 0x8002800` in the log.
**Generally speaking, instructions that modify a register's value have this section formatted as
`rd <new_value>`**

We can look at the next line in the Spike commit log to understand this field for stores.

`core   0: 3 0x80000004 (0x00112023) mem 0x80028000 0x00000000`

**For stores, it follows the format `mem <store_target_address> <data_to_store>`**. We see this 
with `sw x1, 0(x2)` as the contents of x1 (which are initialized to 0 upon program start and 
not modified for the rest of the program) are stored into the address held by `x2` (which is
`0x8002800` from the previous instruction) shown through `mem 0x80028000 0x00000000`

Now, we look at the last instruction demonstrating a load.

`core   0: 3 0x80000008 (0x00011083) x1  0x00000000 mem 0x80028000`

Loads follow the format `rd <loaded_data> mem <load_target_address>` as indicated 
through `x1  0x00000000 mem 0x80028000`. Where `lh x1, 0(x2)` updates register x1 with content 
from the memory address held by x2 (which is still `0x8002800` from the previous instruction) 
and loads a `0` as stored by the last instruction.

For branches, this last field will be completely empty. Instead, you can determine if a branch
occurred by looking at the PC of the next instruction as demonstrated in the below log snippet. 
The first line is the commit of a branch instruction that had its branch condition evaluated 
to true. As a result, we see the next instruction's PC is modified from the default PC + 4.
```
core   0: 3 0x80000014 (0xfe0098e3)
core   0: 3 0x80000004 (0x00028117) x2  0x80028004
```


## Porting `mp_verif`'s `random_tb`

Writing assembly to test your pipelined processor's edge cases is
rather challenging, and, as you remember from `mp_verif`, randomness
can help catch certain classes of issues much more quickly than
writing directed test vectors. To start using `randinst.svh` and
`instr_cg.svh` from `mp_verif` to verify your pipelined processor, you
must port `mp_verif/main_verif/hvl/random_tb.sv` to work with
`mp_pipeline`'s dual-port memory model. First, copy over all three
files:

```bash
$ cp mp_verif/main_verif/hvl/randinst.svh mp_pipeline/hvl
$ cp mp_verif/main_verif/hvl/instr_cg.svh mp_pipeline/hvl
$ cp mp_verif/main_verif/hvl/random_tb.sv mp_pipeline/hvl
```

Now, you should modify `random_tb` to have the following port list:

```systemverilog
module random_tb
import rv32i_types::*;
(
  mem_itf.mem itf_i,
  mem_itf.mem itf_d,
);
```

Then, modify `random_tb.sv` to use the appropriate interface (`itf_i`)
to drive random instructions into your processor, and to respond to
data memory requests via `itf_d`.

Note that the old random testbench is using a `read` and `rmask` interface,
instead of the single `rmask` interface in this MP.
Make sure to change the appropriate code in your random testbench.

Finally, add a line to `top_tb.sv` to instantiate `random_tb`, like so:

```systemverilog
random_tb mem(.itf_i(mem_itf_i), .itf_d(mem_itf_d));
```

Make sure that `magic_dual_port` and `ordinary_dual_port`
instantiations are commented out if you're using the `random_tb`.
