import json
import subprocess
import os
import sys
import string

allowed_char = set(string.ascii_lowercase + string.ascii_uppercase + string.digits + "._")

os.chdir(os.path.dirname(os.path.abspath(__file__)))
os.chdir("..")

with open("options.json") as f:
    j = json.load(f)

if "dw_ip" not in j:
    print('key "dw_ip" not in options.json', file=sys.stderr)
    exit(1)

if not all([set(x) <= allowed_char for x in j["dw_ip"]]):
    print("illegal character in options.json", file=sys.stderr)
    exit(1)

for i in j["dw_ip"]:
    result = subprocess.run(f"grep -nw {i} sim/vcs_warn.config", shell=True, stdout=subprocess.PIPE)
    if result.returncode == 1:
        with open("sim/vcs_warn.config", "a") as f:
            f.write("{\n    +lint=none;\n    +module=" + i + ";\n}\n")
