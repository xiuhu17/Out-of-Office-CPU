# Ventilator
A Verilator testing suite for ECE 411.

# Table of Contents

1.  [Why use this?](#org9b466a5)
2.  [Requirements](#org5e0b394)
3.  [Initial Setup](#org85dcb53)
4.  [Usage](#org5582d71)
5.  [Working from Home](#orgd06206d)
6.  [Final Comments](#org26130a9)

> NOTE: THIS TESTING SETUP IS ONLY FOR PERSONAL USE. PASSING OR FAILING A TEST ON VERILATOR HOLDS NO WEIGHT ON YOUR GRADE.


<a id="org9b466a5"></a>

# Why use this?

One of the biggest gripes we tend to have with VCS is its runtime - VCS does a lot of event management under the hood, and as a result takes a very long time to simulate big programs like Coremark. However in ECE 411, when we want to see how good our architectural changes are in terms of IPC, this can be prohibitive in testing.

Enter Verilator! By simulating your design on *only* clock edges, it manages to cut down simulation time significantly - like "running Coremark in 3 seconds" significantly.

There are tradeoffs to consider here - Verilator only supports dual-state simulation (0s and 1s), and it doesn't support a lot of advanced SystemVerilog constructs that VCS might. As a result, if your SV does not meet lint standards (which is likely will not initially), you will have to go back and fix your HDL to meet Verilator standards. However in return, you receive much faster simulation times when testing extra credit or performing design space explorations.

Additionally, since Verilator is open source, ***you are able to run Verilator on your local machines***. There are some files that you will need to generate on EWS to do so, and we will discuss this in the "work from home" section, but this can be a game-changer for students with bad internet connections or trying to work from home.


<a id="org5e0b394"></a>

# Requirements

You will need to install the `verilator` program on your system. If you choose to generate waveforms, then you will need to install the `gtkwave` program. If you are on Windows, then it is advised to use WSL to follow along. Most linux distributions and Mac OS will have both the aforementioned packages in their package manager (`homebrew`, `apt`, etc.).

If you are following this guide on EWS,. `verilator` has already been installed for you, and is loaded as part of the `setup_ece411.sh` script you run to gain `vcs` access. However, we were unable to set up `gtkwave` - as a result, you will need to use `verdi` instead.


<a id="org85dcb53"></a>

# Initial Setup

Unfortunately, there is some conflict between the LRM support that Verilator and VCS support - as a result, you will need to restructure your `hvl` directory so that Verilator does not detect any VCS-only files.

With the exception of the below listed files, please move every other file in the `hvl` directory into a subdirectory called `vcs` - this will not affect how your normal VCS tests run, but will make sure that Verilator doesn't freak about simulation constructs.

    mon_itf.sv
    rvfimon.v
    rvfi_reference.json
    rvfi_reference.svh (may not exist, that is ok)

You will now need to make sure that your `options.json` file in the top-level directory is correctly configured - specifically the clock period. The maximum clock period supported at this time is 66ns - going any higher can cause simulation errors or inconsistencies with the "prime" VCS model.

Finally, change the module header in `rvfimon.v` to the following. This is done to avoid a filename issue.

    /* verilator lint_off DECLFILENAME */
    module riscv_formal_monitor_rv32imc (
    /* verilator lint_on DECLFILENAME */

You will want to do something similar in `pkg/types.sv` to avoid any issues with your package name (wrap your package name this time).

Verilator can be rather pedantic when it comes to SystemVerilog style due to how it works internally - as a result, there is a high chance that you will run into many errors and/or warnings when first running Verilator. If you are relatively confident in your code style, you may add some of the following flags to the `verilator` run in `sim/ventilator.mk`.

    -Wno-fatal                 // Disable fatal exit on warnings
    -Wno-lint                  // Disable all lint warnings
    -Wno-style                 // Disable all style warnings

However these flags have been known to cause compilation and runtime errors with Verilator, which could otherwise be avoided by correcting warnings. If you are sure that your design is safely linting with VCS tooling, you may consider the above if there are a prohibitively high number of warnings. Note that Verilator also supports a number of `lint_off` directives as comments in your code - see their [documentation](https://verilator.org/guide/latest/extensions.html?highlight=lint_off#cmdoption-verilator-32-lint_off) for more information on this.


<a id="org5582d71"></a>

# Usage

The default target used to run Verilator assumes that you have the RISC-V toolchain installed and would like to compile an `lst` file from an `ELF`. That is to say, the same syntax as you would use when running a VCS sim. This target is formatted as follows.

    make -f ventilator.mk ventilate PROG="<elf file path>"

This will run your program in Verilator with no traces produced. Since Verilator generates VCD traces, it can dump huge files over the course of a program run - in fact Coremark can generate up to 15GB of traces for a basic superscalar pipeline. However, if you look at the `sim` directory, you should see a file called `progress.ansi` formatted as follows:

    COMMIT     1000 -- CYCLES:     3113 -- IPC 1000: 0.321234 -- CUM IPC: 0.321234
    COMMIT     2000 -- CYCLES:     7715 -- IPC 1000: 0.217297 -- CUM IPC: 0.259235
    COMMIT     3000 -- CYCLES:    10750 -- IPC 1000: 0.329489 -- CUM IPC: 0.279070
    ...

This file tells you on what cycle certain commits completed, what the IPC was for the last 1000 commits, and what the current cumulative IPC of your program is. We recommend using this file in conjuction with other logging mechanisms to determine a "region of interest", and dump traces for those cycles specifically. For example, let's say that I'm curious to see what's going on in my pipeline for the second 1000 commits - we can see that the cycle range for that is 3113 to 7715. I can dump traces for these commits specifically by running the following:

    make -f ventilator.mk ventilate PROG="<elf file path>" START_CYCLE=3113 END_CYCLE=7715

You will now see a VCD file in the `sim` directory. This can be opened with `gtkwave` or any other digital file viewer (on `ews`, you can use `verdi` or the vscode extension `wavetrace`). Be careful when generating these traces - specifying too wide of a cycle range can quickly pollute your hard drive or network disk.


<a id="orgd06206d"></a>

# Working from Home

If working from home, there are two key components that you would not have installed by default - Synopsys Library Compiler, used for generating SRAM models, and the 32-bit RISC-V ELF GCC tools. The former cannot be installed locally, so you will need to make your SRAM models on EWS then download the folder locally (specifically `sram/output`). The RISC-V GCC tools can be used to make the default `ventilate` target work, but alternatively you can use `bin/generate_memory_file.sh` to generate memory `lst` files on EWS, download the file locally, then run the following target:

    make -f ventilator.mk ventilate_manual MEMFILE="<lst file path>"

This target supports the same cycle arguments that the default target does as well. Note that you will need to download the file generated with *8-bit addressability* - by default, this is `sim/sim/memory_8.lst`.


<a id="org26130a9"></a>

# Final Comments

Ventilator is a great tool to use for additional benchmarking and some basic debug in large program runs, but it can by no means be used as a singular or exhaustive verification tool.

Please note that there will be some differences between your Verilator and VCS simulation results, however staff testing has indicated a difference of +-20 cycles total simulation time over the course of a program. If you notice exaggerated differences in reported VCS and Verilator simulation results, please contact course staff ASAP - this tooling is still highly experimental, and you may have found a bug.

If you have any feedback or feature requests, please submit them to either the course Discord or Campuswire.

