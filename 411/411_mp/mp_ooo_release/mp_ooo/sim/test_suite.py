# This does NOT check for program correctness
# Ensure each program runs correctly before using this!

import subprocess
import math
import os

FAIL = '\033[91m'
ENDC = '\033[0m'

# get from synthesis
AREA = 1

# add more performance counters here!
perf_counters = [
    # Add any performance counters you want here. 
    # These will be string matched from the output of your
    # testbench, so use the $display command to display
    # your performance counters!
    
    # Note - make sure every performance counter is on a new line
    # Examples:
    # Branch predictor accuracy : x%
    # Dcache hit rate: y%
    
    # example perf counter
    # 'Branch accuracy',
    
    # leave these for benchmarking
    'Segment IPC',
    'Segment Time',
    'Power',
    'Test Weight',
    'Weighted Benchmark Score', 
]
weighting_const = 9926.12616
# test, weight
benchmarks = {
    # all benchmark weights are computed as:
    # 1 or 2 depending on test importance
    # divided by number of instructions for that test without the full M extension
    # times a constant so the sum of weights is close to 1
    'fft.elf' : weighting_const * 2 / 134941,
    'graph.elf' : weighting_const * 1 / 115028,
    'rsa.elf' : weighting_const * 1 / 158470,
    'compression.elf' : weighting_const * 2 / 90633,
    'dna.elf' : weighting_const * 1 / 104740,
    'mergesort.elf' : weighting_const * 1 / 92136,
    'physics.elf' : weighting_const * 2 / 226354,
    'sudoku.elf' : weighting_const * 1 / 76170,
    '../coremarks/coremark_im.elf': weighting_const * 2 / 308350,
    # uncomment these if you have div/rem instructions working
    # 'physics_d.elf' : 1,
    # 'rsa_d.elf': 1
}

def run_program(prog):
    result = subprocess.run(['make', 
                             'run_top_tb', 
                             f'PROG={prog}'], stdout=subprocess.PIPE)
    results_str = result.stdout.decode()
    result_lines = results_str.split('\n')
    perf_count_info = {p : '-' for p in perf_counters}
    
    if 'Sim failed' in results_str:
        return False, perf_count_info
    
    for perf_counter in perf_counters:
        for line in result_lines:
            if perf_counter in line:
                # Perf counters in rvfi must be in certain format for this
                value = line.split(' ')[-1]
                perf_count_info[perf_counter] = value
                break    
    
    return True, perf_count_info

def run_power(prog):
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    os.chdir("../synth")
    result = subprocess.run(['make', 
                             'power'], stdout=subprocess.PIPE)
    
    power_result = subprocess.run(['python3', 
                             'get_power.py'], stdout=subprocess.PIPE)
    os.chdir("../sim")
    return float(power_result.stdout.decode())

def to_markdown(bench_info, full_score, filepath):
    with open(filepath, "w") as f:
        f.write(f'## Benchmark results:\n')
        f.write(f'|Test Name')
        for k in perf_counters:
            f.write(f'|{k}')
        f.write('|\n')
        lb = (len(perf_counters)+1)*'|-'
        f.write(f'{lb}|\n')
        for b, info in bench_info.items():
            f.write(f'|{b}')
            for v in info.values():
                f.write(f'|{v}')
            f.write('|\n')
        f.write(f'## Overall Competition Score:\n')
        f.write(f'{full_score}\n')
            
            

def main():
    all_bench_info = {}
    total_score = 0
    for benchmark, weight in benchmarks.items():
        print(f'Processing {benchmark}')
        prog = f'../testcode/competition_suite/{benchmark}'
        sim_passed, info = run_program(prog)
        print(f'Running power on {benchmark}')
        power = run_power(prog)
        if sim_passed:
            test_score = weight * math.sqrt(AREA) * power * (float(info['Segment Time']))**3
        else:
            print(f"{FAIL}Sim failed on program {prog}, please investigate{ENDC}")
            test_score = 1e50
        info['Weighted Benchmark Score'] = test_score
        info['Test Weight'] = weight
        info['Power'] = power
        all_bench_info[benchmark] = info
        total_score += test_score
    to_markdown(all_bench_info, total_score, 'benchmark_results.md')
    
if __name__ == '__main__':
    main()

