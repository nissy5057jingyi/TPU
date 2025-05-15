# TPU Accelerator for ESP

This project integrates a TPU-style hardware accelerator into the [ESP (Embedded Scalable Platform)](https://www.esp.cs.columbia.edu/) framework. It enables efficient convolutional neural network (CNN) inference with support for fixed-point arithmetic and hardware acceleration of matrix operations via a systolic array.

## Overview

The design includes:

- **Q5.3 fixed-point** arithmetic for efficient CNN computation
- **Systolic array** implementation for matrix and convolution operations
- **APB (Advanced Peripheral Bus)** interface for configuration and control
- **DMA-based memory access** for high-throughput data transfer
- Modular RTL design for both **standalone simulation** and **ESP integration**

## RTL Source Directories

- **TPU RTL**: `TPU/esp/accelerators/rtl/tpu_rtl`
- **Memory Copier RTL**: `TPU/esp/accelerators/rtl/mem_copier_rtl`

## Accelerator Features

- 16×16 systolic array for matrix multiply and im2col-based convolution
- APB-mapped configuration and status registers
- Hardware support for:
  - Pooling
  - ReLU and Tanh activation functions
  - Normalization
- DMA interface for data transfer
- Bare-metal software testbench for integration testing

## Getting Started

To run the TPU and mem_copier accelerators within the ESP platform, follow these steps:

### Prerequisites

- ESP repository cloned and built on a supported platform (e.g., VC707)
- SystemVerilog-compatible simulation environment (e.g., ModelSim)
- Bare-metal cross-compilation toolchain

### Setup Instructions (RTL Simulation)

```bash
# Navigate to the ESP platform for your board
cd <esp>/socs/xilinx-vc707-xc7vx485t

# Build HLS modules (if applicable)
make example_rtl-hls

# Configure the SoC to include your RTL accelerators
make esp-xconfig    # Make sure to enable TPU and mem_copier in the config menu

# Build the software (bare-metal) test program
make example_rtl-baremetal

# Run RTL simulation using ModelSim
TEST_PROGRAM=./soft-build/<cpu>/baremetal/example_rtl.exe make sim
