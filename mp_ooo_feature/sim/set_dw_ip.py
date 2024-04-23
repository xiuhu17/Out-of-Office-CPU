import json
import subprocess
import os

os.chdir(os.path.dirname(os.path.abspath(__file__)))
os.chdir("..")

with open("options.json") as f:
    j = json.load(f)

result = subprocess.run("sed -i -E 's/^(DW_IP +?:=).*?$/\\1 " + ' '.join(['\\$(DW)\/sim_ver\/' + x + '.v' for x in j['dw_ip']]) + "/g' sim/Makefile", shell=True, stdout=subprocess.PIPE)
if result.returncode != 0:
    print(result.stdout.decode())
    exit(1)

for i in j["dw_ip"]:
    result = subprocess.run(f"grep -nw {i} sim/vcs_warn.config", shell=True, stdout=subprocess.PIPE)
    if result.returncode == 1:
        with open("sim/vcs_warn.config", "a") as f:
            f.write("{\n    +lint=none;\n    +module=" + i + ";\n}\n")
