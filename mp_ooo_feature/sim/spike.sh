#/bin/bash

make spike ELF=./bin/dependency_test.elf
cmp ./sim/commit.log ./sim/spike.log