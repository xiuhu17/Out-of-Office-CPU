#/bin/bash

make spike ELF=./bin/rsa_d.elf
cmp ./sim/commit.log ./sim/spike.log