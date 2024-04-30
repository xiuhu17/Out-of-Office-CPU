
# ECE 411: mp_ooo ADVANCED_FEATURES

Below is a list of possible advanced features you can implement following CP3 and their associated point values.

This list is not exhaustive. If you have a cool idea, talk to your mentor TA and they will assign a fair amount of points for it.

## Advanced Features to Consider Early

### Superscalar (15+2 points)

Out-of-order processors exploit instruction level parallelism for better performance. Why not exploit it some more?

A superscalar processor is a processor that can handle >1 instructions in the same clock cycle at every stage: Fetch, Decode, Dispatch, Issue, Writeback, Commit, etc. The *superscalar width* of a processor is the minimum number of instructions each stage can handle in the same clock cycle.

For example, a processor that fetches only 1 instruction at a time is not superscalar, even if the rest of the processor can handle more than one instruction simultaneously. A processor with a minimum width of 2 would be called a 2-way superscalar processor. A parametrized-width processor would be called an N-way superscalar processor.

Without stalls, a 2-way superscalar processor should be able to achieve an IPC of 2.0 for highly parallel programs.

If you are interested in this feature, you should plan ahead when writing your code. Either make your processor superscalar from the start, or write your code clearly so you can easily extend it later.

### Early Branch Recovery (15 points)

Your out-of-order processors have a deep pipeline. It can take dozens of clock cycles before a branch makes its way to the head of the ROB. Therefore,
mispredicted branches can have a large impact on performance. Think about how in mp_pipeline you have to flush several stages whenever you mispredict a branch. This problem becomes worse as you add more stages, and out-of-order processors can be hurt even more significantly. 

When you mispredict a branch, there may be several instructions elsewhere in your pipeline that should not be committed. In mp_pipeline, we could recover in a relatively straightforward manner by squashing branches at pipeline stages earlier than the branch. This is not so straightforward in an out-of-order processor. For example, it can be tricky to keep track of which instructions are younger than others. If you directly implement the processor described in lecture, the only structure that maintains program order is the ROB. Consequently, the simplest way to handle mispredicts is to flush everything when committing a mispredicted branch (and no earlier). Depending on exactly when the branch commits, this can take a long time, resulting in a very large mispredict penalty.

Early branch recovery solves this by adding logic to your pipeline to enable branches to flush only instructions younger than themselves before commit. In the most ideal case, as soon as the branch is resolved, you can squash all of the incorrectly fetched instructions. 

If you are interested in this feature, you should consider from the beginning how to tag instructions in your processor with the metadata necessary for squashing logic. This can be especially tricky with explicit register renaming.

### Speculative Loads / Data Predictor (20 points)

Memory instructions are a little tricky to handle properly in an out-of-order processor. One reason for this is that loads and stores use values held in registers to determine source/target memory addresses. This means the dependencies between loads and stores cannot always be statically determined - conflicts arise during runtime based on the register values. To ensure correctness, loads cannot grab values from memory until all older stores' destination addresses are determined. This can cause long, often unnecessary stalls - loads and stores are frequently not to the same memory address.

One way to improve performance in this scenario is to support speculative load execution. This is typically combined with structures such as load-store queues. Thus, the points allocated to speculative load execution includes the points for load-store queues. In addition to those structures (which you will start considering around CP3), you also need to handle the prediction and mispredict squashing logic. 

If you are interested in this feature, you should start by considering how to handle the squashing logic and the logic for informing loads that they were mispredicted. Later (near CP3), you will then start executing these speculative loads in whichever way you see fit to implement.

## Other Advanced Features (points tentative)

### Memory Execution:

### Memory Execution:

- Memory Disambiguation
  - Load ordering, store ordering (AMD K6 style) [5]
  - Partial ordering (including OoO load issue, like MIPS R1000) [10]
    - With complex store-forwarding (cache request and update with mask from conflicting store) [5]
  - Store ordering (speculative loads with rollback) (Alpha 21264 or Fire and Forget) [20]
- Post-Commit Store Buffer [5]
  - With write Coalescing [1]
### Cache:

- Multibanked Cache [4]
- Pipelined Cache ([4] read-only, [6] read/write)
- Non-Blocking Data Cache [10]
- Fully Parametrized Cache ([2] sets, [4] ways if PLRU)

### Prefetchers:

- Next-Line Prefetcher [3]
- Stride Prefetcher [4]
- Fetch Directed Instruction Prefetching [8]
- Other better Prefetcher

### Branch Predictors (max 2 predictors):

- BTB (Branch Target Buffer) [2]
- TAGE [8]
- Perceptron [8]
- GShare/GSelect [4]
- Local History Table [2]
- Combination:
  - Tournament/Hybrid/Combined [2]
  - Overriding branch prediction [8 if also using TAGE/Perceptron]
- Return Address Stack [3]

### RISC-V Extensions:

- M (Multiplication and Division) Extension
  - Advanced Multiplier (Dadda [6], Wallace [5], Booth [2])
  - Advanced Divider (Synopsys IP) [3]
- C (Compressed Instructions) Extension [8]
- F (Floating Point) Extension (Synopsys IP) [up to 15]

### Misc:

- Early Tag Broadcast [5]
- Non-synthesizable model of the entire processor to verify against (cycle accurate) [up to 10]
- High-quality visualization of processor state using cocotb [up to 8]