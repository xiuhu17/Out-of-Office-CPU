#/bin/bash

set -e

cd vcs

if [ ! -f xprop.log ] || grep -q ' NO' xprop.log; then
    echo -e "\033[0;31mXProp failed \033[0m"
    exit 1
else
    echo -e "\033[0;32mXProp Successful \033[0m"
    exit 0
fi
