import json
import os
import string

required_list = [
    "valid"     ,
    "order"     ,
    "inst"      ,
    "rs1_addr"  ,
    "rs2_addr"  ,
    "rs1_rdata" ,
    "rs2_rdata" ,
    "rd_addr"   ,
    "rd_wdata"  ,
    "pc_rdata"  ,
    "pc_wdata"  ,
    "mem_addr"  ,
    "mem_rmask" ,
    "mem_wmask" ,
    "mem_rdata" ,
    "mem_wdata" 
]

allowed_char = set(string.ascii_lowercase + string.ascii_uppercase + string.digits + "._")

os.chdir(os.path.dirname(os.path.abspath(__file__)))
os.chdir("../hvl")

if os.path.isfile("rvfi_reference.svh"):  
    os.remove("rvfi_reference.svh")

with open("rvfi_reference.json") as f:
    j = json.load(f)

if not all([x in j for x in required_list]):
    print("incomplete list in rvfi_reference.json")
    exit(1)

if not all([x in required_list for x in j]):
    print("spurious item in rvfi_reference.json")
    exit(1)

if not all([set(j[x]) <= allowed_char for x in j]):
    print("illegal character in rvfi_reference.json")
    exit(1)

with open("rvfi_reference.svh", 'w') as f:
    f.write("always_comb begin\n")
    for x in j:
        f.write(f"    mon_itf.{x} = {j[x]};\n") 
    f.write("end\n")
