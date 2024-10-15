#/bin/bash

set -e

cd vcs

if [ ! -f compile.log ] || grep -q 'Error-' compile.log; then
    echo -e "\033[0;31mCompile failed \033[0m"
    exit 1
elif grep -q 'Warning-\|Lint-' compile.log; then
    echo -e "\033[0;33mCompile finished with warnings \033[0m"
    exit 69
else
    echo -e "\033[0;32mCompile Successful \033[0m"
    exit 0
fi
