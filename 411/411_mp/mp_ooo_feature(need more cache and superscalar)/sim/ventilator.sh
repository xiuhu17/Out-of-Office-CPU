#bin/bash
SHPWD=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
MEMFILE="$(pwd)/$1"
cd $SHPWD

python3 ../bin/rvfi_reference.py

CFG=$(find $(pwd)/../pkg -name '*.sv')
HDL=$(find $(pwd)/../hdl -name '*.sv')
HVL=$(find $(pwd)/../hvl -maxdepth 1 -name '*.sv' -o -name '*.v')
SRAM=$(find $(pwd)/../sram/output -name '*.v')
HVLDIR="${SHPWD}/../hvl"

CLOCK_PERIOD_PS=$(cat ../synth/clock_period.txt)

mkdir -p sim
find ./sim -maxdepth 1 -type f -delete
cd sim

# generates compile commands json now
verilator -Wall -Wno-UNUSEDPARAM -Wno-UNUSEDSIGNAL -Wno-BLKSEQ -Wno-WIDTHTRUNC -Wno-GENUNNAMED -Wno-WIDTHEXPAND -trace --trace-structs --cc +define+LOGGING -Dclock_period_ps=1250 $CFG $HDL $HVL $SRAM "${HVLDIR}/ventilator/ventilator_monitor.sv" "${HVLDIR}/ventilator/verilator_tb.sv" --top-module verilator_tb -Mdir vent_exhaust --exe --build  "${HVLDIR}/ventilator/top_tb.cpp" \

if [ $? -eq 0 ]; then
    echo "Running simulation..."
    "./vent_exhaust/Vverilator_tb" ${CLOCK_PERIOD_PS} $MEMFILE "${@:2}"
    # uncomment above, use below for logging runtime
    # "./vent_exhaust/Vverilator_tb" ${CLOCK_PERIOD_PS} "$@" 2>&1 | tee runtime.log
else
    echo FAILED
fi
