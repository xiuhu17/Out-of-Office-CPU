import json
import os
import sys

os.chdir(os.path.dirname(os.path.abspath(__file__)))
os.chdir("..")

with open("options.json") as f:
    j = json.load(f)

if "synth" not in j:
    print('key "synth" not in options.json', file=sys.stderr)
    # exit(1)
    j["synth"] = {
        "compile_ultra" : True,
        "ungroup"       : True,
        "gate_clock"    : True,
        "retime"        : True
    }

cmd = ""

if j["synth"]["compile_ultra"]:
    cmd += "compile_ultra"
else:
    cmd += "compile"

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
