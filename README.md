# TPU Accelerator for ESP

This project integrates a TPU-like accelerator into the [ESP framework](https://www.esp.cs.columbia.edu/) with:

- Q5.3 fixed-point arithmetic
- DMA-based memory access
- APB-configurable control registers
- Hardware convolution via **im2col** and a systolic array

## Features

- 16×16 systolic array for matrix/convolution ops
- APB-mapped control/status registers (CSR)
- Pooling, activation (ReLU/Tanh), normalization
- Modular RTL with standalone and ESP integration
- Fully validated with DMA + C-based testbench

## Usage (ESP on VC707)

```bash
cd <esp>/socs/xilinx-vc707-xc7vx485t
make example_rtl-hls
make esp-xconfig    # Include TPU accelerator
make example_rtl-baremetal
TEST_PROGRAM=./soft-build/<cpu>/baremetal/example_rtl.exe make sim
````

For FPGA:

```bash
make fpga-run
```

## Status

✅ RTL and ESP integration
✅ DMA + APB testbench validation
⚠️ Partial end-to-end simulation
⚠️ APB timing refinement pending

## Next Steps

* Finalize full-pipeline simulation
* Add interrupts / timeout handling
* Extend for deeper networks (e.g., attention layers)

