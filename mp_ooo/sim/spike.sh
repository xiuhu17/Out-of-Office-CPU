#/bin/bash

make spike ELF=./bin/ooo_test.elf
diff ./sim/commit.log ./sim/spike.log