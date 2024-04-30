#/bin/bash

if [ ! -f reports/synthesis.log ] || grep -iwq -f synth-error-codes reports/synthesis.log; then
    echo -e "\033[0;31mSynthesis failed:\033[0m"
    grep -iw -f synth-error-codes reports/synthesis.log
    exit 1
fi

if [ ! -f reports/timing.rpt ] || ! grep -iq 'slack (MET)' reports/timing.rpt; then
   echo -e "\033[0;31mTiming Not Met \033[0m"
   exit 1
else
   echo -e "\033[0;32mTiming Met \033[0m"
fi

if grep -iq 'warning' reports/synthesis.log; then
    echo -e "\033[0;33mSynthesis finished with warnings:\033[0m"
    grep -i 'warning' reports/synthesis.log
    exit 2
else
    echo -e "\033[0;32mSynthesis Successful \033[0m"
fi

exit 0
