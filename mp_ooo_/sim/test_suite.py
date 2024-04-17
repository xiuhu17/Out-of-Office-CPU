# This does NOT check for program correctness
# Ensure each program runs correctly before using this!

import subprocess
import math

FAIL = '\033[91m'
ENDC = '\033[0m'

# get from synthesis
AREA = 1

# TBD
POWER = 1

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
    'Test Weight',
    'Weighted Benchmark Score', 
]

# test, weight
benchmarks = {
    'fft.elf' : 1,
    'graph.elf' : 1,
    'rsa.elf' : 1,
    'compression.elf' : 1,
    'dna.elf' : 1,
    'mergesort.elf' : 1,
    'physics.elf' : 1,
    'sudoku.elf' : 1,
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
        if sim_passed:
            test_score = weight * math.sqrt(AREA) * POWER * (float(info['Segment Time']))**2
        else:
            print(f"{FAIL}Sim failed on program {prog}, please investigate{ENDC}")
            test_score = 1e50
        info['Weighted Benchmark Score'] = test_score
        info['Test Weight'] = weight
        all_bench_info[benchmark] = info
        total_score += test_score
    to_markdown(all_bench_info, total_score, 'benchmark_results.md')
    
if __name__ == '__main__':
    main()

