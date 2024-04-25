#/bin/bash

make spike ELF=./bin/coremark.elf
cmp ./sim/commit.log ./sim/spike.log