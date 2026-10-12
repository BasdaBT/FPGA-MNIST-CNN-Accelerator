# FPGA MNIST CNN Accelerator

[![Verilog CI](https://github.com/BasdaBT/FPGA-MNIST-CNN-Accelerator/actions/workflows/verilog.yml/badge.svg)](https://github.com/BasdaBT/FPGA-MNIST-CNN-Accelerator/actions/workflows/verilog.yml)

An 8-bit quantized convolutional neural network inference pipeline implemented in Verilog HDL for the Digilent Basys 3 (Xilinx Artix-7) FPGA. The design reads a 28×28 MNIST image from block ROM, evaluates the network sequentially, and displays the predicted digit on the board's seven-segment display.

## Architecture

```text
28×28×1 uint8 image
        │
        ▼
3×3 Conv2D, 4 filters, stride 1 + ReLU     26×26×4 (32-bit accumulators)
        │
        ▼
2×2 MaxPool, stride 2 + requantization     13×13×4 (int8)
        │
        ▼
Flatten                                      676 values
        │
        ▼
Dense 676→32 + ReLU + requantization
        │
        ▼
Dense 32→32 + ReLU + requantization
        │
        ▼
Dense 32→10 + argmax                         predicted digit
```

The datapath uses synchronous ROM/RAM interfaces and finite-state machines to reuse multiply-accumulate hardware across the network. Intermediate feature maps and dense-layer outputs are stored in inferred block RAM.

## Repository layout

| Path | Purpose |
| --- | --- |
| `rtl/` | CNN layers, memories, top-level integration, and Basys 3 UI wrapper |
| `tb/` | End-to-end testbench |
| `constraints/` | Basys 3 pin and clock constraints |
| `memory/` | Manifest for the required model and image initialization files |
| `docs/` | Original project report in DOCX and browser-friendly PDF formats |

Important entry points:

- `rtl/basys3_cnn_demo.v` — board top module; `btnC` resets, `btnU` starts inference, `led[0]` indicates completion, and AN0 displays the result.
- `rtl/cnn_top.v` — inference pipeline and inter-layer control.
- `rtl/cnn_top_with_rom.v` — compact simulation/integration wrapper.
- `tb/tb_cnn_top.v` — end-to-end testbench with a 5 ms timeout.

## Required model data

The Verilog ROMs load nine external hexadecimal text files with `$readmemh`. These trained weights, biases, and test-image values were not included in the supplied source bundle, so they are intentionally not fabricated in this repository. See [`memory/README.md`](memory/README.md) for the exact filenames, shapes, and expected widths.

Place the files in the simulator's working directory, or add them to the Vivado project as memory initialization sources while keeping the expected basenames. Without them, the RTL can be elaborated but a meaningful inference simulation or bitstream cannot be reproduced.

## Simulation

With Icarus Verilog and all nine initialization files available in the current directory:

```bash
mkdir -p build
iverilog -g2012 -Wall -s tb_cnn_top -o build/cnn_tb.vvp rtl/*.v tb/tb_cnn_top.v
vvp build/cnn_tb.vvp
```

The current source tree has been successfully elaborated with Icarus Verilog 12.0 for both `tb_cnn_top` and `basys3_cnn_demo`. A control-flow smoke test using temporary zero-filled memories also completed two consecutive inference runs without reset. This does not validate classification accuracy; functional classification was not rerun because the trained memory files were absent.

## Basys 3 implementation

1. Create a Vivado RTL project for `xc7a35tcpg236-1`.
2. Add every file under `rtl/` as a design source.
3. Add the nine model-data files listed in `memory/README.md` as memory initialization sources.
4. Add `constraints/basys3_cnn_demo.xdc` and select `basys3_cnn_demo` as the top module.
5. Run synthesis, implementation, and bitstream generation.
6. Program the board, press `btnC` to reset, then press `btnU` to start inference.

`DIV_TOGGLE` defaults to 5, producing an approximately 10 MHz CNN clock from the 100 MHz board oscillator.

## Verification status

| Check | Status |
| --- | --- |
| RTL syntax and module elaboration | Passed with Icarus Verilog 12.0 |
| Two-run control-flow smoke test | Passed with synthetic zero-filled memories; approximately 1.60 ms per run at 100 MHz simulation clock |
| Restart-safe layer handshakes | Corrected to use one-cycle start/done pulses |
| Functional inference | Blocked by missing trained memory files |
| Vivado synthesis/timing | Not rerun in this repository |
| Reported project result | The report states that ten supplied test images matched the Python reference and that the Basys 3 demo produced stable predictions |

The last row records the academic report's result; it is not presented as an independently reproduced benchmark.

## Documentation and credits

- [Project report (PDF)](docs/Project_Report.pdf)
- [Original project report (DOCX)](docs/Project_Report.docx)

Academic final project, Kocaeli University, Department of Electronics and Communication Engineering, January 2026.

- **Authors:** Burak Taha Başda and [Ömer Şahin](https://github.com/OmerSahinkou)
- **Advisor:** Dr. Mahmut Burak Karadeniz

No open-source license is currently provided. Please contact the project authors before reusing the source beyond review or educational reference.
