import json
import os
import string

required_list = [
    "valid[0]"     ,
    "order[0]"     ,
    "inst[0]"      ,
    "rs1_addr[0]"  ,
    "rs2_addr[0]"  ,
    "rs1_rdata[0]" ,
    "rs2_rdata[0]" ,
    "rd_addr[0]"   ,
    "rd_wdata[0]"  ,
    "pc_rdata[0]"  ,
    "pc_wdata[0]"  ,
    "mem_addr[0]"  ,
    "mem_rmask[0]" ,
    "mem_wmask[0]" ,
    "mem_rdata[0]" ,
    "mem_wdata[0]" ,

    "valid[1]"     ,
    "order[1]"     ,
    "inst[1]"      ,
    "rs1_addr[1]"  ,
    "rs2_addr[1]"  ,
    "rs1_rdata[1]" ,
    "rs2_rdata[1]" ,
    "rd_addr[1]"   ,
    "rd_wdata[1]"  ,
    "pc_rdata[1]"  ,
    "pc_wdata[1]"  ,
    "mem_addr[1]"  ,
    "mem_rmask[1]" ,
    "mem_wmask[1]" ,
    "mem_rdata[1]" ,
    "mem_wdata[1]" ,

    "valid[2]"     ,
    "order[2]"     ,
    "inst[2]"      ,
    "rs1_addr[2]"  ,
    "rs2_addr[2]"  ,
    "rs1_rdata[2]" ,
    "rs2_rdata[2]" ,
    "rd_addr[2]"   ,
    "rd_wdata[2]"  ,
    "pc_rdata[2]"  ,
    "pc_wdata[2]"  ,
    "mem_addr[2]"  ,
    "mem_rmask[2]" ,
    "mem_wmask[2]" ,
    "mem_rdata[2]" ,
    "mem_wdata[2]" ,

    "valid[3]"     ,
    "order[3]"     ,
    "inst[3]"      ,
    "rs1_addr[3]"  ,
    "rs2_addr[3]"  ,
    "rs1_rdata[3]" ,
    "rs2_rdata[3]" ,
    "rd_addr[3]"   ,
    "rd_wdata[3]"  ,
    "pc_rdata[3]"  ,
    "pc_wdata[3]"  ,
    "mem_addr[3]"  ,
    "mem_rmask[3]" ,
    "mem_wmask[3]" ,
    "mem_rdata[3]" ,
    "mem_wdata[3]" ,

    "valid[4]"     ,
    "order[4]"     ,
    "inst[4]"      ,
    "rs1_addr[4]"  ,
    "rs2_addr[4]"  ,
    "rs1_rdata[4]" ,
    "rs2_rdata[4]" ,
    "rd_addr[4]"   ,
    "rd_wdata[4]"  ,
    "pc_rdata[4]"  ,
    "pc_wdata[4]"  ,
    "mem_addr[4]"  ,
    "mem_rmask[4]" ,
    "mem_wmask[4]" ,
    "mem_rdata[4]" ,
    "mem_wdata[4]" ,

    "valid[5]"     ,
    "order[5]"     ,
    "inst[5]"      ,
    "rs1_addr[5]"  ,
    "rs2_addr[5]"  ,
    "rs1_rdata[5]" ,
    "rs2_rdata[5]" ,
    "rd_addr[5]"   ,
    "rd_wdata[5]"  ,
    "pc_rdata[5]"  ,
    "pc_wdata[5]"  ,
    "mem_addr[5]"  ,
    "mem_rmask[5]" ,
    "mem_wmask[5]" ,
    "mem_rdata[5]" ,
    "mem_wdata[5]" ,

    "valid[6]"     ,
    "order[6]"     ,
    "inst[6]"      ,
    "rs1_addr[6]"  ,
    "rs2_addr[6]"  ,
    "rs1_rdata[6]" ,
    "rs2_rdata[6]" ,
    "rd_addr[6]"   ,
    "rd_wdata[6]"  ,
    "pc_rdata[6]"  ,
    "pc_wdata[6]"  ,
    "mem_addr[6]"  ,
    "mem_rmask[6]" ,
    "mem_wmask[6]" ,
    "mem_rdata[6]" ,
    "mem_wdata[6]" ,

    "valid[7]"     ,
    "order[7]"     ,
    "inst[7]"      ,
    "rs1_addr[7]"  ,
    "rs2_addr[7]"  ,
    "rs1_rdata[7]" ,
    "rs2_rdata[7]" ,
    "rd_addr[7]"   ,
    "rd_wdata[7]"  ,
    "pc_rdata[7]"  ,
    "pc_wdata[7]"  ,
    "mem_addr[7]"  ,
    "mem_rmask[7]" ,
    "mem_wmask[7]" ,
    "mem_rdata[7]" ,
    "mem_wdata[7]"
]

allowed_char = set(string.ascii_lowercase + string.ascii_uppercase + string.digits + "._'[]")

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
