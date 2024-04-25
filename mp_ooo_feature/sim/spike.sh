#/bin/bash

make spike ELF=./bin/graph.elf
cmp ./sim/commit.log ./sim/spike.log