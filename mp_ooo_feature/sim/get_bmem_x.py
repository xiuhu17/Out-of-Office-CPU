import json
import os

os.chdir(os.path.dirname(os.path.abspath(__file__)))
os.chdir("..")

with open("options.json") as f:
    j = json.load(f)

print(int(j["bmem_0_on_x"]))
