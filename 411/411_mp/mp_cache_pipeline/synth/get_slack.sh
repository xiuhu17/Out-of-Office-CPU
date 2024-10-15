#/bin/bash

set -e
sed -nr 's/ +slack \([A-Z]+\) +(-?[0-9]+?\.[0-9]+?)$$/\1/p' reports/timing.rpt
