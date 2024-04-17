## Out-Of-Order Competition Tests

These are some of the test cases we will run on your out-of-order processor for the competition. 

**Note:** we will also run some hidden test cases not mentioned here. More test cases may be released later.

- RSA Encryption
	- Uses Square-multiply algorithm of exponentiation to perform RSA encryption on small messages
	- Uses modular arithmetic, so heavily benefits from a divider
	- Has strong branch correlation
- DNA Sequence Alignment
	- Computes sequence alignment on two DNA sequences.
	- Has branch correlation
	- Has mostly linear access pattern

- Compression
	- Computes Huffman Encoding
	- Linear data streaming

- Recursive Sudoku Solver
	- Rercursive code
	- Many helper functions
	- Easter egg: This is from ECE 220!

- Physics sim
	- Performs Matrix-Multiplication for mesh transformations, and uses GJK algorithm for collision detection
	- Heavy on arithmetic instructions
	- Many helper functions
	- Computes averages, so benefits from a divider

- FFT
	- Computes approximation of FFT on a signal
	- Recursive

- Graph traversal
	- Random access on a linked data structure
	- Performs computation on each node with strong ILP
	- Easter egg: Performs BitBeast operations from your first Midterm!

- Sorting
	- Performs recursive out of place mergesort
	- Using many loads and stores
	- Recursive
