import json
import sys
import os

os.chdir(os.path.dirname(os.path.abspath(__file__)))
os.chdir("..")

with open("options.json") as f:
    j = json.load(f)

if "bmem_0_on_x" not in j:
    print('key "bmem_0_on_x" not in options.json', file=sys.stderr)
    exit(1)

print(int(j["bmem_0_on_x"]))
