import json
import sys
import os
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

print(' '.join([os.environ["DW"] + '/sim_ver/' + x + '.v' for x in j['dw_ip']]))
