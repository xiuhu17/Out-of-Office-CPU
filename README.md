Superscalar Tomasulo out-of-order execution CPU(two in-order issue, out-of-order execution, four in-order commits). Pipelined, PLRU, 4-way, Write-Back, Write-Allocate, I-Cache & D-Cache connect with single port Banked Burst Dram. Implement GShare bimodal and Perceptron Branch Prediction together with BTB Jump Table. Memory disambiguation with store_queue&store_buffer -> load_res forwarding, post-commit store buffer. Implement modified Dadda multiplier(10 cycles) and Synopsys DW_div_seq IP(16 cycles) to support full RV32-M Extension. Now could achieve 440 MHz(freq), 197753μm2(area), 0.67 IPC, 36mW(power) on average testing on mergesort, rsa encryption, fft, etc testcode. 

Link to the project: https://github.com/xiuhu17/Out-of-Office-CPU/tree/main/411/411_mp/mp_ooo_feature(need%20more%20cache%20and%20superscalar)

Run synthsis: under synthesis folder, run ```make synth``` \
Run lint: under lint folder, run ```make lint``` \
Run simulation: under sim folder, run ```./run.sh```

Overview of the entire hdl design with full advance features which are build from scratch: https://github.com/xiuhu17/Out-of-Office-CPU/tree/main/411/411_mp/mp_ooo_feature(need%20more%20cache%20and%20superscalar)/hdl_w_mem_disambiguation

Future feature: full superscalar, lock-up free data cache with MSHR \& MAF, mordern cache prefetcher, speculative load with squash logic
