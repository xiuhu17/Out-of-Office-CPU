import subprocess
import os

allowed_sv_tasks = [
    "signed",
    "unsigned",
    "cast",
    "bits",
    "unpacked_dimensions",
    "dimensions",
    "left",
    "right",
    "low",
    "high",
    "increment",
    "size",
    "clog2",
    "countbits",
    "countones",
    "onehot",
    "onehot0",
    "fatal",
]
sus_keywords = ["translate_off", "DPI"]
search_dir = ["hdl", ]

os.chdir(os.path.dirname(os.path.abspath(__file__)))
os.chdir("..")

allowed_sv_tasks = '|'.join(allowed_sv_tasks)
search_dir = ' '.join(search_dir)

found = False
log = ""

result = subprocess.run(f"grep -rn -P '\$(?!({allowed_sv_tasks}))' {search_dir}", shell=True, stdout=subprocess.PIPE)
if result.returncode != 1:
    found = True
    log += result.stdout.decode()

for s in sus_keywords:
    result = subprocess.run(f"grep -rn '{s}' {search_dir}", shell=True, stdout=subprocess.PIPE)
    if result.returncode != 1:
        found = True
        log += result.stdout.decode()

if found:
    print("\033[31m" + "Forbidden Keyword Found: " + "\033[0m")
    print(log)
    exit(1)
else:
    exit(0)
