#!/usr/bin/python3

import json
import sys
import os
import string
import subprocess

os.chdir(os.path.dirname(os.path.abspath(__file__)))
os.chdir("..")

with open("options.json") as f:
    j = json.load(f)

if sys.argv[1] == "synth_inc_iter":
    iter = int(j["synth"]["inc_iter"])
    if iter > 10 or iter < 0:
        print("Error: Synthesis incremental iterations need to be within 0 and 10", file=sys.stderr)
        exit(1)
    print(int(j["synth"]["inc_iter"]))

if sys.argv[1] == "synth_cmd" or sys.argv[1] == "synth_cmd_inc":
    cmd = ""

    if j["synth"]["compile_ultra"]:
        cmd += "compile_ultra"
        if sys.argv[1] == "synth_cmd_inc":
            cmd += " -incremental"
    else:
        cmd += "compile"
        if sys.argv[1] == "synth_cmd_inc":
            cmd += " -incremental_mapping"

    if j["synth"]["compile_ultra"]:
        if not j["synth"]["ungroup"]:
            cmd += " -no_autoungroup"
    else:
        if j["synth"]["ungroup"]:
            cmd += " -ungroup_all"

    if j["synth"]["gate_clock"]:
        cmd += " -gate_clock"

    if j["synth"]["retime"]:
        if j["synth"]["compile_ultra"]:
            cmd += " -retime"
        else:
            print("Error: compile non ultra does not support retime", file=sys.stderr)
            exit(1)

    print(cmd)
