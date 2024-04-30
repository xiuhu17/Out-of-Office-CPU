import json
import sys
import os

os.chdir(os.path.dirname(os.path.abspath(__file__)))
os.chdir("..")

with open("options.json") as f:
    j = json.load(f)

if "synth" not in j or "min_power" not in j["synth"]:
    print('key "min_power" not in options.json', file=sys.stderr)
    # exit(1)
    j["synth"] = {"min_power": False}

print(int(j["synth"]["min_power"]))
