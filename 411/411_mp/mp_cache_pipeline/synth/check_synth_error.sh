#/bin/bash

set -e

AREA_LIMIT=50000

if [ ! -f reports/synthesis.log ] || grep -iwq -f synth-error-codes reports/synthesis.log; then
    echo -e "\033[0;31mSynthesis failed \033[0m"
    exit 1
fi

if [ ! -f reports/timing.rpt ] || ! grep -iq 'slack (MET)' reports/timing.rpt; then
   echo -e "\033[0;31mTiming Not Met \033[0m"
   exit 1
else
   echo -e "\033[0;32mTiming Met \033[0m"
fi

if [ ! -f reports/area.rpt ] || [ $(bash get_area.sh) -gt $AREA_LIMIT ]; then
    echo -e "\033[0;31mArea Not Met \033[0m"
    exit 1
else
    echo -e "\033[0;32mArea Met \033[0m"
fi

if grep -iq 'warning' reports/synthesis.log; then
    echo -e "\033[0;33mSynthesis finished with warnings \033[0m"
    exit 69
else
    echo -e "\033[0;32mSynthesis Successful \033[0m"
    exit 0
fi
