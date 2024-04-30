# ECE 411: mp_verif GUIDE

## Introduction to SystemVerilog and Verification

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

**This document, GUIDE.md, serves as a gentle, guided tour of the MP. For
strictly the specification and rubric, see [README.md](./README.md).**

It is highly recommended that you use the automatically generated
table of contents/outline to navigate this page, accessed by clicking
the "bullet points" icon on the top right of the markdown preview
pane.

# Introduction
Welcome to the first machine problem in ECE 411: Computer Organization
and Design! This MP assumes that you are familiar with basic RTL
design using SystemVerilog from ECE 385: Digital Systems Laboratory.
In this MP, you will learn some more advanced concepts in
SystemVerilog and verification. You will also become familiar with the
tools used in ECE 411, including the simulation, synthesis, and lint
programs. This MP is divided into four parts:

1. **SystemVerilog refresher:** You'll design a small module in
   SystemVerilog as a refresher, and to get familiar with the
   toolchain used in this class.
2. **Fixing common errors:** Logical errors, latches, combinational
   loops, and long critical paths are common issues that RTL designers
   face. In this part of the MP, you will identify and fix these
   issues in a couple of simple designs.
3. **Constrained random and coverage:** Writing directed test vectors isn't a lot
   of fun, and often doesn't have good coverage. In this part, you'll
   learn how to use constrained random vector generation and coverage
   collection to better verify complex designs.
4. **Verification of a CPU:** Finally, a CPU! You will find
   bugs in a simple multicycle RISC-V CPU implementation by using your
   knowledge from parts 1-3. 

# SystemVerilog Refresher

## On SystemVerilog
SystemVerilog is a hardware description language and a hardware verification
language. You've previously used SystemVerilog in ECE 385 to implement some
basic digital circuits on FPGAs. In ECE 411, we'll use SystemVerilog to design
more involved digital circuits. There are two primary "tasks" when describing
hardware in RTL ([register-transfer
level](https://en.wikipedia.org/wiki/Register-transfer_level)): **simulation**
and **synthesis**. 
- Simulation means using a software program to "mock" the operation of the
  circuit to ensure functional correctness. ECE 411 uses an industry standard
  simulator: Synopsys VCS.
- Synthesis is the process of turning the RTL into gates and flip flops,
  typically done using a synthesis tool. In ECE 411, we will use Synopsys Design
  Compiler (DC) using the
  [FreePDK45](https://eda.ncsu.edu/freepdk/freepdk45/) process design kit.
  
In the first part of this MP, you will write an RTL design and put it
through both simulation and synthesis. 

## Linear Feedback Shift Registers
The design you are required to implement is a **linear feedback shift
register** (LFSR). These are used to generate pseudorandom sequences
of bits cheaply in both hardware and software. Here's the block
diagram of the LFSR you will implement:

![LFSR block diagram](./docs/images/lfsr_block_diagram.svg)

The 16-bit register is a shift register that shifts right. The bit
shifted in is the XOR of certain "tap bits", and the bit shifted out
is the random output. The location of the taps has been chosen such
that the period of the LFSR is maximum[^1] (that is, it cycles through all
$2^{16}$ possibilities before looping back to the initial state). 

## Understanding the Implementation

The expected behavior waveform is:

![LFSR waveform](./docs/images/lfsr_waveform.svg)

Waveforms can tell us a lot about a circuit. First, notice that `rst`
is high for the first few cycles. After reset, the value of the shift
register is `0xeceb` -- this is the seed of the LFSR. Then, `en` is
pulsed for a clock cycle. The LFSR makes its transition, and the
output on `rand_bit` is the last bit of `0xeceb` that got shifted out.
You should verify, on paper, that `0xeceb -> 0xf675` is the correct
transition for the LFSR shown above. Also trace out the later
transitions, making sure you verify the values of `shift_reg` and
`rand_bit` on paper manually.

You might have noticed that `rand_bit` is shaded gray when it is not directly
after an `en` pulse. This notation means that the output of `rand_bit` is
don’t care, meaning that it can be any value. When don’t care is used in say
for example a input of your design, it means that the signal can take any value
and it should not affect the operation of your design.

## Running a Simulation

First, see the folder structure with:

```bash
$ cd sv_refresher
$ tree
```

You should see the output:

```
.
├── hdl
│   └── lfsr.sv
├── hvl
│   └── top_tb.sv
├── lint
│   ├── lint.awl
│   ├── lint.tcl
│   └── Makefile
├── sim
│   ├── Makefile
│   └── vcs_warn.config
└── synth
    ├── check_synth_error.sh
    ├── dc-gui.tcl
    ├── Makefile
    ├── synth-error-codes
    └── synthesis.tcl
```

This minimal folder structure will be the same across all designs in
ECE 411:
- `hdl` contains synthesizable RTL.
- `hvl` contains non-synthesizable testbenches used for simulation and
  verification.
- `lint` contains scripts to run lint on your design in `hdl`
- `sim` contains scripts to run simulation on your design in `hdl`
- `synth` contains scripts to run synthesis your design in `hdl`

For now, your LFSR design will go in `hdl/lfsr.sv`. For this part of the
MP, the testbench is provided fully implemented in `hvl/top_tb.sv`. In
the next part of this MP, these training wheels are removed and you
will write both the RTL and testbench. Once you implement some RTL in
`hdl/lfsr.sv`, run the testbench in simulation with:

```bash
$ cd sim
$ make run_top_tb
```

This should run VCS, and you will see a pass/fail result. Now, pull up
Verdi (the waveform viewer), with:

```bash
$ make verdi &
```

Verdi is a large, complex program that deserves much explanation.
However, getting started is easy: in the source browser, click on any
signal that you want to look at (start with `clk`), then type
`Ctrl-W` (or `Ctrl-4` if you are using FastX).
The signal will be shown in the waveform. Verdi is
discoverable and rather intuitive: click around to see what you can
do. If you had a failure, track it down by using the timestamp printed
in the error message. Once you see the bug, fix your RTL, rerun the
simulation, then reload the waveform in Verdi with `Shift-L`.

## Running Synthesis

After $n$ Verdi debug cycles, you should pass simulation. It's time to
see if your design can actually be turned into gates to be put on a
chip. To run synthesis, do:

```bash
$ cd synth
$ make synth
```

Once synthesis finishes running (and you get the "Synthesis
Successful" text), check out the reports in `synth/reports`. The two
of primary interest are `timing.rpt` and `area.rpt`. There are no area
limits in this MP, but meeting timing is important. Informally,
"meeting timing" means that your circuit can successfully run at the
specified clock frequency (in this case, 100MHz). We will talk more
about timing in the next part. For now, make sure that your LFSR passes
timing (the slack is a positive number).

## Hints

Recall the SystemVerilog concatenation operator (`{}`) can be used to
implement a left shift register in the following way:

```systemverilog
// Recall: always_ff @(posedge clk) implements positive-edge clocked D flip flops
always_ff @(posedge clk) begin
  shift_reg <= {shift_reg, shift_in};
end
```

Note that the top bit of the right hand side is discarded when
assigning back to `shift_reg`. How would you change this to implement
a right-shift register? How would you compute the bit that's shifted
in?

# Part 2.1: Fixing Common Errors: ALU

## On Common Errors
While designing a digital circuit, various types of "bugs" can creep
in. Here are some common ones we've seen in past semesters:
- **Logical/functional errors**: A design has incorrect functionality. For
  instance, it raises a signal that shouldn't be raised.
- **Accidentally inferred latches**: When defining combinational
  logic, if every case is not written down, SystemVerilog infers a
  memory element called a latch. This is usually not intentional.
- **Long critical paths**: Due to circuit timing characteristics, only
  a certain amount of combinational delay can happen in a single clock
  cycle. Too much combinational logic between FFs can cause timing to
  "fail". The longest such delay path is called the "critical path".
- **Combinational loops**: Explained in the next section.

In this exercise, we provide an ALU design that suffers from the first
three of these bugs, and your task is to fix these bugs. Combinational
loops are split into a separate exercise that you'll do next.

## ALU

When looking at an unfamiliar SystemVerilog module, the most useful
thing to look at is often the port list/interface:

``` systemverilog
module alu (
  input               clk,
  input               rst,
  input [63:0]        a,       // 64-bit input a
  input [63:0]        b,       // 64-bit input b
  input [3:0]         op,      // operation code
  input               valid_i, // valid signal for inputs
  output logic [63:0] z,       // 64-bit output z
  output logic        valid_o  // valid signal for z
);
```

What does this interface tell us? 
- The ALU has two 64-bit inputs, `a` and `b`.
- The operation is selected using a 4-bit code called `op`.
- To trigger an ALU operation, the user sets `valid_i` high.
- After some number of cycles, the ALU responds with `z`, a 64-bit
  output.
- When responding, it sets `valid_o` high.

This information is gleaned from the naming of the signals and the
comments. Since the ALU is such a simple design, the only other bit of
information we need is the `op` code encodings:

| Operation | `op` Code |
| --- | --- |
| Bitwise AND | 0 |
| Bitwise OR  | 1 |
| Bitwise NOT | 2 |
| Add | 3 |
| Subtract | 4 |
| Increment | 5 |
| Left shift | 6 |
| Right shift | 7 |
| Population count | 8 |

Some of these are unary operations (they only require one input, like
bitwise NOT and POPCNT) -- these are defined to act on input `a` and
ignore input `b`. Now, taking a look at the waveform, we see that our
understanding of the ALU's behavior is correct:

![ALU waveform](./docs/images/alu_waveform.svg)

The interesting thing to note about this waveform is the broken lines
across each wave. This means that the ALU could respond after an
unspecified number of clock cycles. This will be useful later when we
are optimizing the critical path.

## Issues with `hdl/alu.sv`

The data above is enough to write a very quick implementation of the
ALU, as provided in `hdl/alu.sv`. However, this design has bugs, as
discussed earlier. Of course, you could completely remove the contents
of the module and write it from scratch, but it's much more
instructive and useful for future MPs if you learn to fix the issues
in the given design. 

### Inferred Latches

Latches are inferred in SystemVerilog if you have an `always_comb`
block that holds a value across evaluations. For instance, in the case
of a 3:1 MUX,

```systemverilog
always_comb begin
    case (sel)
        2'b00: out = a;
        2'b01: out = b;
        2'b10: out = c;
    endcase
end
```

This will infer a latch. Imagine a case where the block is evaluated
at `sel == 2'b01` and `out` is assigned to a. Then `sel` changes to
`2'b11`. What is `out` now?

The correct answer according to SystemVerilog semantics is that it
holds its previous value, thus inferring a memory element,
specifically, a latch. To ensure you're not inferring memory elements
in your combinational logic, ensure that your outputs are assigned a
value for every evaluation path (i.e., they never have to implicitly
hold the value from the previous evaluation).

Here's a couple of ways to fix the latch in the above example:
```systemverilog
always_comb begin
    out = 'x;
    case (sel)
        2'b00: out = a;
        2'b01: out = b;
        2'b10: out = c;
    endcase
end
```

Alternately, (we highly recommend this method):

```systemverilog
always_comb begin
    unique case (sel)
        2'b00: out = a;
        2'b01: out = b;
        2'b10: out = c;
        default: out = 'x;
    endcase
end
```

There are cases when only adding a `default` to your case statement
isn't sufficient: you need to ensure that all of the possible
evaluation (control) paths assign a value to the variable.

Finding latches is easy: You can run either lint or synthesis.
Our synthesis flow disallows inferred latches, and will report it as
an error:

```bash
$ cd common_errors/synth
$ make synth
```

Reading `reports/synthesis.log` will tell you which variables in the
ALU became inferred latches.

```bash
$ cd common_errors/lint
$ make lint
```

Reading `reports/lint.rpt` will tell you which variables in the
ALU became inferred latches.

### Logical/Functional Errors

These are the most common class of real "errors", and are found by
writing testbenches for verification. You wrote some simple
testbenches in ECE 385, and in ECE 411 you'll use more powerful
techniques to write high-quality SystemVerilog testbenches.
Verification is a very large part of digital design, and many
ASIC/FPGA interviews you'll get right out of college will be for
verification roles. 

Part of the testbench for the ALU has been provided at
`hvl/top_tb.sv`. You should first read through this file to make sure
you understand everything that's going on. If there are any
SystemVerilog keywords that you're unfamiliar with, you should look
them up (or ask a TA!) to make sure you have a solid understanding of
how to write a basic testbench. There are a number of incomplete
`TODO`s in this testbench -- work through them in order until you are
able to fix the functional errors in the provided ALU.

Finally, your testbench must have 100% "coverage". Coverage is a way
to measure whether you've tested your design thoroughly enough. For a
combinational design with $n$ inputs, to test every input, you need
to try $2^n$ possible input combinations. This isn't feasible for a
somewhat large $n$. (What is $n$ for the ALU?) Thus, the testbench
sends in some subset of possible test vectors to the DUT (design under
test). Coverage is a way of measuring that these vectors tested enough
interesting cases. In essence, coverage is "statistics collection" on
your input test vectors.

The coverage for this part of the MP has been
written for you, and is in `hvl/coverage.svh`. For you to get full
credit on your testbench, you must sample this covergroup every time
you generate a transaction. At the end of the simulation, your
coverage must be 100%. It's important to learn to view the coverage
report to see what coverage you're missing. To do this, run:

```bash
$ cd common_issues/sim
$ make run_top_tb        # Uses the testbench in hvl/top_tb.sv
$ make covrep            # Generate the coverage report in sim/urgReport/dashboard.html
```

To actually open the HTML file, you have three choices:

- If you're on FastX/X-forwarding or in person at the lab:
  ```bash
  $ firefox sim/urgReport/dashboard.html
  ```
- If you're on SSH and prefer to use your local web browser, on your
  local shell, do:
  ```bash
  $ ssh -L 8000:localhost:8000 netid@linux.ews.illinois.edu
  ```
  Then, on EWS, navigate to `mp_verif/common_issues/sim/sim/urgReport`,
  and do:
  ```bash
  $ python3 -m http.server 8000 &
  ```
  Now, on your local machine, navigate to
  http://localhost:8000/dashboard.html, and you should see the
  coverage report.
- Use your favorite file transfer tool to download the report onto
  your local computer and open it there.

The coverage report looks like the following (if you haven't sampled
the covergroup at all):

![Coverage Dashboard](./docs/images/cov_report1.png)

In the navbar, click on "Groups", then on "top_tb::cg" in the second
table on the page. You should see a detailed breakdown of each
coverpoint in the covergroup (at this point, none will be covered):

![Group](./docs/images/cov_report2.png)

As you feed more stimulus into the DUT and sample the covergroup, your
coverage will go up. Rerun `make run_top_tb && make covrep`, then
reload the page to see the updated coverage. The page should look like
this:

![Coverage done](./docs/images/cov_report3.png)

If you see this, you're done writing the testbench!

### Long Critical Paths
Meeting a high clock frequency is often a desirable goal for digital
designers. However, a circuit cannot be run at an arbitrarily high
clock speed, as there are constraints for timing that must be met.

First, a quick recap of ECE 385. Gates have parasitic
capacitance and it takes time to charge and discharge them. Flip-flops
have two requirements: input data needs to be correct a certain time
before the clock edge, called the **setup time**, and data needs to be held
at the correct value for a certain time after the clock edge, called the **hold time**.
This delay plus the combinational delay together means that the circuit
can only operate at a certain frequency, otherwise the data captured
by the flip-flop might be incorrect. The actual equations are:

$$t_{setup} + t_{comb} + t_{cq} \leq T_{clk}$$

$$t_{cq} + t_{comb} \geq t_{hold}$$

where $t_{setup}$ is the setup time, $t_{hold}$ is the hold time,
$t_{comb}$ is the delay of the combinational logic, $t_{cq}$ is the
clock-to-Q delay of the flip-flop, and $T_{clk}$ is the time period of
the clock. The first inequality (setup time equation) is of interest, since it
determines the maximum clock frequency. We would like to minimize
$T_{clk}$, therefore we want to minimize the left hand side of that
equation. The factor most in your control as an RTL designer is
$t_{comb}$ -- that is, the combinational delay between two flip flops.
Graphically,

![Comb paths](./docs/images/tcomb.svg)

In this case, the `comb2` stage has more delay than the `comb1` stage,
and therefore is the "critical path" of the design -- it is the path
that is limiting the clock frequency. To optimize a circuit for a
higher clock speed, a critical path is the first one you try to
optimize. Once you have, a new path may become the critical path, but
likely the circuit can meet higher clock speed now. A good goal as a
digital design engineer is to have "balanced" amounts of combinational
delay in each stage and each path.

You would definitely like to know where is your critical path so that
you can have some idea of how to improve it. Once you run synthesis:
`$ cd synth && make synth`, a timing report will be generated at
`common_errors/synth/reports/timing.rpt`. You are "meeting timing" if
the slack number at the bottom is positive. This table also traces out
the critical path of the design. However, the path listed here is at
the gate level, and it is not exactly easy to link it back to your
design.

You can use Design Compiler’s GUI to link it back to your deisgn.
To launch the GUI after you are done with `make synth`, run:

```bash
$ make dv
```

On the right hand side of the GUI, select "Cells (All)" in the top right drop down,
find the cell you are looking for, right click on it, and "cross probe to source".
This will show you which line in your source code this gate comes from.

Now we know where the critical path is. What next? If we are confined
within restrictions such as the ALU operation needing to be done in a
certain amount of cycles, then we have to resort to optimizations such
as rearranging the combinational logic to minimize delay. For this
exercise specifically, since we do not restrict the delay (in cycles)
of this ALU, you can simply break up some sections of the critical
path into multiple cycles by adding registers in between. This
technique (you will learn this in detail in lecture later)
is often called "pipelining the critical path". Here is a
demonstration. Consider a 4:1 MUX:

![mux](./docs/images/mux.svg)

Now, assume this MUX doesn't meet timing *and is the critical path*.
What can we do to fix it? Recall from ECE 120 that a 4:1 MUX is the
same as three cascaded 2:1 MUXes:

![cascaded mux](./docs/images/cascaded_mux.svg)

Now, inserting flip flops between these cascaded MUXes can ease the
critical path (this is called pipelining):

![pipelined mux](./docs/images/piplined_mux.svg)

The tradeoff here should be evident: instead of the MUX
responding combinationally, this "pipelined MUX" will now take two
clock cycles to respond. However, each of these cycles takes less time
since the clock frequency can now be higher.
In the ALU, to meet a frequency of 700MHz, you will need to pipeline
the output MUX in the same way, along with optimizing other critical
paths in the design.

# Part 2.2: Fixing Common Errors: Combinational Loops

The design has three modules:

- `a.sv`: A module with a down-counter that generates the `ack` pulse
  when its counter matches an input value and `req` is high.
- `b.sv`: A module with an up-counter that sends its value along with
  a `req` signal to `a`, to generate the `ack` pulse.
- `top.sv`: Top level module.

Another common issue that might arise in your ECE 411 journey is a
combinational loop. This is, when you have some combinational logic
where the input depends on its own output. In ECE 120, flip-flops are
implemented using a similar kind of combinational logic. Specifically,
they are stable loops, wherein the value generated is guaranteed to converge
to a single stable value within some timeframe after a change in input. However,
in ECE 411 we think at a higher level of abstraction, so flip-flops are simply a
primitive in our tool-chain. For the purposes of this course, you will not
(and should not) write any combinational loops, stable or otherwise.

In this exercise, you will debug a given design that has a very
obvious loop. This exercise is more about how to use the provided 
tools to find it.

One telltale sign of a non-stable combinational loop is an indefinitely
hanging simulation, where no matter how long you wait before
you press `Ctrl-C`, the simulated time is always stuck at the exact same value.
This is because there are cyclic dependencies in the sensitivity lists
of multiple `always` blocks. Thus, the simulator is never able to progress
to the next timestep.

Both lint and synthesis can tell you where the loop is.

Synthesis will tell you there is a loop both on the console and in
`synth/reports/synthesis.log`. The loop will be shown in the same
gate level notation as the timing report.

Lint will tell you where the loop is, using signal names from your RTL.
Simply run lint and check `lint/reports/CombLoopReport.rpt`.

The goal of this exercise is to fix the loop. The testbench specifies
what the end result should look like. Any modification that will test
the testbench constitutes a pass. However, we recommend you find the
loop and fix it instead of doing testcase oriented programming.


# Part 3: Constrained Random and Coverage

## Constrained Random
As discussed earlier, a design with $n$ binary inputs has $2^n$
possible input combinations. However, not all of these $2^n$ may be
valid inputs to the DUT. For example, for the ALU provided in
`common_errors`, `op` cannot actually take on all its possible values.
Now, if we want to **randomly generate valid inputs** to the ALU, we
cannot simply pick any random 4-bit number. Instead, we must
"constrain" the randomness to be only the valid 4-bit numbers for
`op`. This can be done in SystemVerilog with "Constrained random value
generation", and is an extremely powerful technique. Here is what a
class that generates valid `op` values looks like:

```systemverilog
class RandOp;
  rand bit [3:0] op;

  constraint op_valid_c {
    op < 4'd9;
  }
  
endclass : RandOp
```

The constraint should be self-explanatory. Variables qualified with
`rand` must be class members. Having a `rand` variable automatically
defines a `randomize()` method on the class. So, to actually get a
valid `op` value, you would do:

```systemverilog
RandOp rop = new();

initial begin
  rop.randomize();
  $display("Got new random op: %x", rop.op);
  rop.randomize();
  $display("Got new random op: %x", rop.op);
  // ... and so on
end
```

Clearly, the idea of constraints is very general. There are many cases
where only a subset of inputs is actually valid. Constrained random
can be used to generate packets of certain formats, or valid
instructions for a CPU. This is your task: you must complete the
random class in `hvl/randinst.svh` called `RandInst` to randomly
generate valid RISC-V instructions. You will likely find the types
defined in `pkg/types.sv` extremely useful when writing the random
constraints. The best reference for this part is Chapter 19
RV32/64G Instruction Set Listings of the [RISC-V 2.2
Specification](https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf).
A constraint will be required wherever Table 19.2 (the RV32I
subsection) lists hardcoded binary values, since that dictates the
subspace of valid instruction vectors. 
We also strongly recommend you that read Chapter 2 of the
specification as well, because it provides detailed explanation of 
what exactly each instruction does. This is useful for understanding RISC-V
as well as for the last part of the MP.

## Functional Coverage
You've used functional coverage reports while writing the ALU to make
sure that your directed test vectors had enough coverage. Now, you
will write the SystemVerilog to evaluate the coverage of your random
constraints. Take a look at `hvl/instr_cg.svh`. The first few
coverpoints are simple enough to implement. The "cross coverpoints"
are trickier, and this section explains how to reason about them. What
we want to do is ensure that every row in the following table is
covered at least once:

![spec table](./docs/images/spec_ss.png)

Now, consider trying to cover all instructions that use `funct7`.
Clearly, that is the bottom 13 rows of the table. To actually put
these 13 "bins" into the coverage report, in SystemVerilog, we need to
use "cross coverage". The way we do this is that we first take a cross
product of three fields:

```systemverilog
funct7_cross : cross instr.r_type.opcode, instr.r_type.funct3, instr.r_type.funct7 {
```

This means we want to cover a triple cross product: every possible
opcode (9 possibilities), with every possible `funct3` (8
possibilities), with every possible `funct7` (128 possibilities). The
cardinality of this cross product is 9144: that is, there are 9144
3-tuples that this cross product generates. Of these, we only
care about 13. For example, we do care about the 3-tuple (op=0110011,
funct3=111, funct7=0000000) which represents the AND instruction. So, we need to
ignore a lot of the cross product in our coverage report. This can be
done with `ignore_bins`, like this:

```systemverilog
  funct7_cross : cross instr.r_type.opcode, instr.r_type.funct3, instr.r_type.funct7 {

    // No opcodes except op_reg and op_imm use funct7, so ignore the rest.
    ignore_bins OTHER_INSTS = funct7_cross with
    (!(instr.r_type.opcode inside {op_reg, op_imm}));

  }
```

The `ignore_bins` above says, ignore all members of the cross product
whose opcode is not either `op_reg` or `op_imm`. This makes sense if
you look at the 13 possibilities we want to preserve. The cardinality
of the cross product has now reduced to $2\times 8\times 128 = 2048$.
Your task, both with `funct7_cross` and `funct3_cross` is to add more
`ignore_bins` that ignore members of the cross product that aren't in
the table above. Note that `funct3_cross` is expected to have 31 bins,
corresponding to all rows of the table above (instructions) that have
a true `funct3` field (ignoring `funct7` differences).

## Solve Order
In `RandInst`, there is a constraint:
```systemverilog
constraint solve_order_c { solve instr_type before instr; }
```

`instr_type` is a bit vector that selects which kind of instruction to
generate. In general, 
> The solver shall assure that the random values are selected to give
> a uniform value distribution over legal value combinations (that is,
> all combinations of legal values have the same
> probability of being the solution).
> (IEEE 1800-2017, IEEE Standard for SystemVerilog--Unified Hardware
> Design, Specification, and Verification Language)

This is undesirable in our case, though, since we want the
probability of selecting every instruction type to be roughly equal,
not the overall probability. To resolve this, we need to ask
SystemVerilog to *first* randomize `instr_type`, *then* actually
randomize the instruction. This is a common technique when the value
of a certain random variable determines the value of other random
variables, and results in a better distribution than a purely uniform
one gotten by treating all constraints as equal. You should comment
out the `solve_order_c` constraint and see the coverage report
frequencies for `opcode` -- they will not be uniform as you expect.

You will need to write your own `solve...before` constraint for
`funct3` to get complete coverage, since `funct3` determines `funct7`
for cases in `op_imm` and `op_reg`. Without a solve order constraint,
this results in a skewed distribution that has certain very low
probability cases.

# Part 4: Main Verification Task

The goal of this section is for you to get comfortable debugging and
verifying RISC-V CPUs using this course's infrastructure. The core is
provided in `hdl`, and has a few bugs that you will fix. You can use
both your random instruction generation code from section 3 and by
writing RISC-V assembly: you are free to choose either or both. Using
a combination of both approaches is the recommended method.

## Getting Started
First, copy over the constrained random instruction generation and
coverage code from the previous part to `main_verif/hvl`:

```bash
$ cd mp_verif
$ cp constr_rand_cov/hvl/randinst.svh main_verif/hvl
$ cp constr_rand_cov/hvl/instr_cg.svh main_verif/hvl
```

You are free to not use random testing at all in part 4, but these two
files need to be in the right place and free of syntax errors for the
code to compile.

Now, take a look at the testbench in `main_verif/hvl/top_tb.sv`. For
now, focus on lines 17-19. There are two testbenches you can use:
`simple_memory`, which loads in a program from an assembly file for
your CPU to execute, or `random_tb`, which will use `randinst.svh` to
supply the core with random instructions. We recommend starting with
`random_tb` to do randomized testing, but you can also choose to
instead use `simple_memory` to run assembly directly. 

```bash
$ cd main_verif/sim
$ make run_top_tb PROG=../testcode/riscv_basic_asm.s
```

Note that you must provide an assembly file even if you're using the
random testbench. Although the random testbench ignores it, the
current Make flow requires this variable to be set.

## RVFI Quickstart
RVFI is a handy tool that will snoop the commits of your processor,
and check with the spec to see if your processor has any errors. It
essentially runs another RISC-V core parallel to yours and crosschecks
that your commits are correct. The RVFI file is at
`main_verif/hvl/rvfimon.sv` (you do not have to actually go and read it).
We have already connected it for you in `main_verif/hvl/top_tb.sv`.
Once you run your first simulation, you will likely see two kinds of errors:

```
Error: [...]
Simultaneous read and write to memory model!
```

and 

```
-------- RVFI Monitor error 101 in channel 0: top_tb.monitor.monitor.ch0_handle_error at time 274 --------
Error message: mismatch in [...]
```

Start with the first error -- why is the core trying to read and write
to memory at the same time? Pull up Verdi and debug.

Once you fix the memory read/write issue, take a closer look at RVFI's
error message. (If it is not a mismatch in trap, otherwise go to the
next section.) It should tell you which signal did not match
correctly, and give you more information about:
- Which instruction was executed. You can decode this hex instruction
  with https://luplab.gitlab.io/rvcodecjs/.
- The program counter of the instruction.
- The "order" of the instruction: a number representing the index of
  the instruction. You can pull in the order signal in Verdi to
  track down the offending instruction easily.
- More instruction specific data such as register indexes, values read
  from registers, register writeback value, next PC, etc. If the signal
  is prefixed with "rvfi", it is the signal RVFI got from your CPU.
  If the signal is prefixed with "spec", it is the RVFI’s expected value.

This data, along with tracing signals in Verdi should help you resolve
most CPU bugs.

## Trap Mismatches
A trap mismatch in this CPU will be caused if a load or store
instruction is trying to access memory in a non-naturally aligned
manner. For example, `lw` must only access memory addresses that are
four-byte aligned (bottom two bits of address are zero). Similarly,
`sh` can only store to memory addresses that are 2-byte aligned
(bottom bit of address is zero). If this assumption is violated, a
trap is raised. However, the given core supports neither traps nor
misaligned memory accesses.

The solution here is to never feed the core a load or store
instruction that does a non-naturally aligned access. How can we
guarantee this? The answer is clear when manually writing assembly,
but how do we ensure that our randomly generated loads/stores have
naturally aligned accesses? With some kind of random constraint, but
what is it?

Note that this is a slightly tricky problem, since in RISC-V, the
format of a load/store is:

```asm
lw rd, i_imm[11:0](rs1)
sw rs2, s_imm[11:0](rs1)
```

First, you should constrain the bottom bits of the immediates
correctly. We still have no guarantee that the contents of `rs1` will
have the correct bottom bits. Therefore, you should hardcode a
constraint for `rs1 == x0`. Since `x0` is always zero, the address
tested is simply zero plus the random top bits of the immediate.

Note that this is *very* bad for coverage -- we're only testing 12-bit
addresses, and never fully testing the address computation for loads
and stores. Instead, **you will need to write assembly to ensure the
address computation for loads/stores is completely correct.**

Such tradeoffs between writing complex constraints and simply hitting
coverage with a few simple directed test vectors is common. A hybrid
approach like ours works well. If you prefer, you can choose to test
loads/stores purely through writing assembly instead, and never
generate them in `randinst.svh`.

## Assembly Testing and Spike Quickstart
There are many errors that Spike can catch that RVFI can not,
especially related to memory operations. This is because RVFI models
only architectural state of the processor, not the state of memory. 
A sample assembly file is provided in
`main_verif/testcode/riscv_basic_asm.s`. Switch to `simple_memory` in
`main_verif/hvl/top_tb.sv` and rerun simulation. Now, run Spike with:

```bash
$ cd main_verif/sim
$ make spike ELF=bin/riscv_basic_asm.elf
```

Then, make sure that the instruction traces are the same with:

```bash
$ diff -s sim/spike.log sim/commit.log
```

## More on Spike

Spike is the golden software model for RISC-V. You can give it a
RISC-V ELF file and it will run it for you. You can also interactively
step through instructions, look at all architectural states and also
memory in it. However, it is likely that you do not need these
features for this MP. You would likely only want it to give you the
golden trace for your program.

The compile script in `main_verif/bin` will generate ELF file in
`main_verif/sim/bin`. This compile script are automatically called if
you call `make run_top_tb`.

To run an ELF on spike, run the following command

```bash
$ make spike ELF=PATH_TO_ELF
```

Replace `PATH_TO_ELF` with path to an ELF file Then you can find the
golden Spike log in `main_verif/sim/sim/spike.log`

In addition, code provided in `main_verif/hvl/top.sv` will print out a
log in the exact same format, which can be found at
`main_verif/sim/sim/commit.log`. You can use your favorite diff tool
to compare the two.

When you are trying to run Spike on your own testcode, make sure to
include all the lines about `tohost` in the example testcode, and the
4 linesthat write 1 into `tohost` right before halting.Spike only
terminates when you `sw` into a special 'variable' in your assembly
code, so failing to include these instructions will lead to Spike
getting stuck in the infinite loop.

Spike uses `x5`, `x10`, and `x11` for some internal purposes before it
actually jumps to run the ELF you supplied. Keep this in mind when you
are writing your own test code.


## How loading an assembly file into Verilog actually works
To load a program into your design, we need to generate a memory
initialization file, `memory.lst`, that is placed into the simulation
directory `main_verif/sim/sim`. The `generate_memory_file.sh` script
located in the `main_verif/bin` directory is used to do this.

The `generate_memory_file.sh` script takes a RISC-V assembly file or a
single C file as input, optionally compiles it to assembly, assembles
it into a RISC-V ELF then object file, and converts the object file
into a suitable format for initializing the testbench memory.

The `generate_memory_file.sh` script stores all its intermediate
products in `main_verif/sim/bin`. Notably, it places the ELF version
of your program there, which can be directly fed to Spike. You can
also find the disassembly in there, which will become very useful when
debugging your design.

The `generate_memory_file.sh` script is part of the Makefile and gets
executed automatically every time you `make run PROG=...`


[^1]: To learn more about how to choose the tap locations to satisfy
    this property, take MATH 418 (Abstract Algebra II).
