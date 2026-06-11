# FPGA Implementation of Wider Variant of AES (WAES-256)

This repository contains the VHDL source code and Python reference model for the paper:

> **First Fully Pipelined High Throughput FPGA Implementation and GPU Optimization of Wider Variant of AES**  
> Ahmet Malal, Cihangir Tezcan  
> *Journal of Cryptographic Engineering*, 16:1, 2026  
> https://doi.org/10.1007/s13389-025-00388-2

## Overview

This work presents the first fully pipelined FPGA implementation of WAES-256, the wider variant of AES with a 256-bit block size. The design supports AES-128, AES-256, and WAES-256 through generic parameters, employs composite field arithmetic in the S-box to reduce critical path delay, and uses sub-pipelining across all AES layers to maximize throughput.

**Key throughput results (single core, CTR mode):**

| Platform | AES-128 | AES-256 | WAES-256 |
|---|---|---|---|
| Spartan-7 SP701 | 57.39 Gbps | 57.14 Gbps | 75.73 Gbps |
| Artix-7 AC701 | 54.46 Gbps | 53.33 Gbps | 72.32 Gbps |
| Zynq UltraScale+ ZCU106 | 120.75 Gbps | 106.66 Gbps | 199.46 Gbps |
| Kintex UltraScale+ KCU116 | 122.95 Gbps | 117.52 Gbps | 206.11 Gbps |

**Multi-core WAES-256 on Kintex UltraScale+ KCU116:**

| Cores | Throughput |
|---|---|
| x1 | 206.11 Gbps |
| x2 | 426.66 Gbps |
| x4 | 742.63 Gbps |

## Repository Structure

```
wider_aes/
├── src/                        # VHDL source files
│   ├── rijndael_top.vhd        # Single-core top-level (AES-128 / AES-256 / WAES-256)
│   ├── rijndael_parallel_top.vhd  # Multi-core parallel top-level
│   ├── top_module.vhd          # I/O wrapper for single core (32-bit serial interface)
│   ├── parallel_top_module.vhd # I/O wrapper for multi-core
│   ├── round.vhd               # Full AES round (SubBytes + ShiftRows + MixColumns + AddRoundKey)
│   ├── round_last.vhd          # Final round (no MixColumns)
│   ├── sbox.vhd                # 4-stage pipelined composite field S-box
│   ├── sub_bytes.vhd           # SubBytes layer
│   ├── shift_rows.vhd          # ShiftRows layer
│   ├── mix_column.vhd          # Single MixColumn unit (3-cycle pipelined)
│   ├── mix_columns.vhd         # MixColumns layer (8 parallel units)
│   ├── multby2.vhd             # GF(2^8) multiplication by 2
│   ├── multby3.vhd             # GF(2^8) multiplication by 3
│   ├── add_round_key.vhd       # AddRoundKey layer
│   └── key_gen.vhd             # Key schedule (AES-128 / AES-256 / WAES-256)
├── tb/                         # VHDL testbenches
│   ├── tb_rijndael.vhd         # Top-level testbench
│   ├── mix_columns_tb.vhd      # MixColumns unit test
│   └── sbox_tb.vhd             # S-box unit test
├── py/                         # Python reference model
│   └── rijndael.py             # Full Rijndael (all block/key size combinations)
└── constr/                     # Xilinx Vivado constraints
    └── constraint.xdc          # Clock constraint (1.2 ns period target)
```

## Design Parameters

The top-level module `rijndael_top` is parameterized via generics:

| Generic | Values | Description |
|---|---|---|
| `G_BLOCK_SIZE` | 16 / 32 | Block size in bytes (128-bit or 256-bit) |
| `G_KEY_SIZE` | 16 / 32 | Key size in bytes (128-bit or 256-bit) |

Setting `G_BLOCK_SIZE = 32` and `G_KEY_SIZE = 32` instantiates WAES-256 (14 rounds, 9 cycles/round, 126-cycle pipeline depth).

For multi-core configurations, use `rijndael_parallel_top` with the additional generic:

| Generic | Description |
|---|---|
| `G_NUM_OF_CORES` | Number of parallel encryption cores (e.g., 2 or 4) |

## Pipeline Architecture

Each AES variant has the following pipeline structure:

| Variant | Cycles/Round | Total Rounds | Pipeline Depth |
|---|---|---|---|
| AES-128 (Nb=4, Nk=4) | 7 | 10 | 70 |
| AES-256 (Nb=4, Nk=8) | 7 | 14 | 98 |
| WAES-256 (Nb=8, Nk=8) | 9 | 14 | 126 |

After the initial latency (pipeline fill), the design produces one ciphertext block per clock cycle. Throughput is:

```
T (Gb/s) = BlockSize (bits) × Frequency (Hz) × NumCores / 10^9
```

## Python Reference Model

`py/rijndael.py` implements the full Rijndael algorithm in Python and verifies correctness against the standard test vectors from *The Design of Rijndael* (Daemen & Rijmen, 2002) for all block/key size combinations. Run it directly to execute the verification:

```bash
python3 py/rijndael.py
# Expected output: All Test Passed Successfully.
```

The Python model was used to generate expected outputs for validating the VHDL simulation results reported in the paper.

## Tool and Target Devices

- **EDA Tool:** Xilinx Vivado
- **Target FPGAs:**
  - Spartan-7 SP701 (`xc7s100fgga676-2`)
  - Artix-7 AC701 (`xc7a200tfbg676-2`)
  - Zynq UltraScale+ ZCU106 (`xczu7ev-ffvc1156-2-e`)
  - Kintex UltraScale+ KCU116 (`xcku5p-ffbv676-2-e`)

## Citation

If you use this code in your research, please cite:

```bibtex
@article{malal2026waes,
  author  = {Malal, Ahmet and Tezcan, Cihangir},
  title   = {First Fully Pipelined High Throughput {FPGA} Implementation and {GPU} Optimization of Wider Variant of {AES}},
  journal = {Journal of Cryptographic Engineering},
  volume  = {16},
  number  = {1},
  year    = {2026},
  doi     = {10.1007/s13389-025-00388-2}
}
```

## Related Work

The GPU implementation of WAES-256 (CUDA) is available at:  
https://github.com/cihangirtezcan/CUDA_WAES

## Authors

- **Ahmet Malal** — ASELSAN Inc. & METU Institute of Applied Mathematics (ahmet.malal@metu.edu.tr)  
  *Responsible for the FPGA implementation and all figures.*
- **Cihangir Tezcan** — METU Graduate School of Informatics & SiMer (cihangir@metu.edu.tr)  
  *Responsible for the GPU implementation.*

## Acknowledgements

The work of Cihangir Tezcan was supported by the German Academic Exchange Service (DAAD) and The Scientific and Technological Research Council of Türkiye (TÜBİTAK) 2531 Bilateral Research Cooperation Project under grant number 123N546.
