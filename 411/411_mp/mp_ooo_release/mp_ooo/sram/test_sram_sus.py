import sys
import os
import string
import ast

allowed_class = (
    ast.Assign,
    ast.FormattedValue,
    ast.JoinedStr,
    ast.List,
    ast.Load,
    ast.Module,
    ast.Name,
    ast.NameConstant,
    ast.Num,
    ast.Store,
    ast.Str,
)
allowed_char = set(string.ascii_lowercase + string.ascii_uppercase + string.digits + "._-/")

os.chdir(os.path.dirname(os.path.abspath(__file__)))
os.chdir("config")

found = False
log = ""

for n in os.listdir("."):

    if not set(n) <= allowed_char:
        found = True
        log += n + '\n'

    with open(n) as f:
        node = ast.parse(f.read(), filename=n)

        for i in ast.walk(node):
            if not isinstance(i, allowed_class):
                found = True
                try:
                    log += f"disallowed class {type(i)} found on line {i.lineno} col {i.col_offset}\n"
                except:
                    log += f"disallowed class {type(i)} found\n"

if found:
    print("\033[31m" + "SRAM sus: " + "\033[0m", file=sys.stderr)
    print(log, file=sys.stderr)
    exit(1)
else:
    exit(0)
