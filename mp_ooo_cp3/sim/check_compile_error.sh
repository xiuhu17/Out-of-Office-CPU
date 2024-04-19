#/bin/bash

cd sim

if [ ! -f top_tb_compile.log ] || grep -q 'Error-' top_tb_compile.log; then
    echo -e "\033[0;31mCompile failed:\033[0m"
    grep 'Error-' top_tb_compile.log
    exit 1
elif grep -q 'Warning-\|Lint-' top_tb_compile.log; then
    echo -e "\033[0;33mCompile finished with warnings:\033[0m"
    grep 'Warning-\|Lint-' top_tb_compile.log
    exit 2
else
    echo -e "\033[0;32mCompile Successful \033[0m"
fi

exit 0
