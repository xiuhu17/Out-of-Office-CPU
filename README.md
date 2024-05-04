Superscalar Tomasulo out-of-order execution CPU(multiple in-order issue, out-of order execution, multiple in-order commit). Pipelined, PLRU, 4-way, Write-Back, Write-Allocate, I-Cache & D-Cache with single port Banked Burst Dram. Implement GShare bimodal and Perceptron Branch Prediction together with BTB Jump Table. Memory disambiguation with store-load forwarding, post-commit store buffer. Implement Dadda multiplier and Synopsys DW_div_seq IP to support full M Extension. Now could achieve 440 MHz(freq), 197753μm2(area), 0.67 IPC, 36mW(power) on average testing on mergesort, rsa encryption, fft, etc testcode. (Still working on: full superscalar, lock-up free data cache with MSHR&MAF, instr cache prefetcher)


Link to the project: https://github.com/xiuhu17/Out-of-Office-CPU/tree/main/411/411_mp/mp_ooo_feature(need%20more%20cache%20and%20superscalar)

Run synthsis: under synthesis folder, run [make synth]
Run lint: under lint folder, run [make lint]
Run simulation: under sim folder, run [./run.sh]
