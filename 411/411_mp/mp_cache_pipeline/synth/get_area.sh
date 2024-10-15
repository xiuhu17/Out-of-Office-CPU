#/bin/bash

set -e

sed -nr 's/Total cell area: +?([0-9]+?)\.[0-9]+?$$/\1/p' reports/area.rpt
