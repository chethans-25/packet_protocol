# Simulation Instructions

Run the commands in this document from the project root, where `rtl/`, `tb/`, and `sim/` are direct subdirectories.

## Available UVM tests

- `packet_random_test`: sends ten randomized packets.
- `packet_wr_en_variation_test`: sends ten packets with `valid` and `rd_en` held high while `wr_en` varies. Each packet contains at least one disabled-write cycle at an interior beat.

## Cadence Xcelium

### Prerequisites

- `xrun` must be available on `PATH`.
- GNU Make must be installed.
- The `UVM_HOME` value in `sim/Makefile` must point to the installed Cadence UVM library. Override it on the command line when necessary.

### Terminal mode

Run the default random test:

```bash
make -C sim run
```

Run the write-enable variation test:

```bash
make -C sim run UVM_TEST=packet_wr_en_variation_test
```

Run with a reproducible seed and higher verbosity:

```bash
make -C sim run UVM_TEST=packet_wr_en_variation_test SEED=12345 UVM_VERBOSITY=UVM_HIGH
```

The terminal log is written to `logs/xrun.log`. Waveforms are recorded in `sim/waves.shm`.

### GUI mode

Run the default random test in SimVision:

```bash
make -C sim gui
```

Run the write-enable variation test in SimVision:

```bash
make -C sim gui UVM_TEST=packet_wr_en_variation_test
```

Use a fixed seed when a waveform must be reproduced:

```bash
make -C sim gui UVM_TEST=packet_wr_en_variation_test SEED=12345
```

The GUI log is written to `logs/xrun_gui.log`. To open a waveform database produced by a previous terminal run:

```bash
simvision sim/waves.shm
```

### Useful Xcelium commands

Display the resolved configuration:

```bash
make -C sim print-config
```

Display all supported Makefile options:

```bash
make -C sim help
```

Remove Xcelium-generated simulation files:

```bash
make -C sim clean
```

## Siemens QuestaSim

### Prerequisites

- `vlog` and `vsim` must be available on `PATH`.
- The Questa installation must provide the precompiled `mtiUvm` library.
- The supplied scripts derive the UVM include path from the `vsim` installation directory.

### Terminal mode using the supplied script

Compile and run the default `packet_random_test`:

```powershell
vsim -c -do sim/run_questa.do
```

The script recreates the `work` library, compiles `sim/files.f`, runs until completion, and exits QuestaSim.

### Terminal mode with explicit test selection

Compile the design:

```powershell
vlog -sv -mfcu -L mtiUvm "+incdir+C:/QSIM/verilog_src/uvm-1.1d/src" -f sim/files.f
```

Replace the UVM include directory if QuestaSim is installed somewhere other than `C:/QSIM`.

Run the write-enable variation test:

```powershell
vsim -c -L mtiUvm work.tb_top +UVM_TESTNAME=packet_wr_en_variation_test -sv_seed 12345 -do "run -all; quit -code 0"
```

Run the default random test explicitly:

```powershell
vsim -c -L mtiUvm work.tb_top +UVM_TESTNAME=packet_random_test -sv_seed random -do "run -all; quit -code 0"
```

### GUI mode using the supplied script

Compile, open the GUI, add the write interface, read interface, and FIFO signals to the Wave window, and run the default test:

```powershell
vsim -do sim/run_questa_gui.do
```

The GUI remains open after simulation finishes.

### GUI mode with explicit test selection

First compile with the `vlog` command shown above. Then launch the selected test:

```powershell
vsim -L mtiUvm -voptargs=+acc work.tb_top +UVM_TESTNAME=packet_wr_en_variation_test -sv_seed 12345 -do "log -r /*; add wave -r /tb_top/write_if/*; add wave -r /tb_top/read_if/*; add wave -r /tb_top/dut/*; run -all; wave zoom full"
```

This command keeps the GUI open and records the write interface, read interface, and DUT hierarchy in the Wave window.

### Batch waveform capture

Run the default test without opening the GUI and save all signals to `packet.wlf`:

```powershell
vsim -c -do sim/run_questa_wave.do
```

Open the saved waveform later:

```powershell
vsim -view packet.wlf
```

## Expected result

A passing ten-packet test ends with a report similar to:

```text
[SCOREBOARD] Packet 0 matched
...
[SCOREBOARD] Packet 9 matched
[SCOREBOARD] Compared 10 packet(s)

UVM_WARNING : 0
UVM_ERROR   : 0
UVM_FATAL   : 0
```

For `packet_wr_en_variation_test`, inspect these waveform signals:

- `/tb_top/write_if/valid`: remains high during the generated stimulus cycles.
- `/tb_top/write_if/wr_en`: changes between high and low, including an interior low cycle in every packet.
- `/tb_top/read_if/rd_en`: remains high after the read-ready sequence starts.
- `/tb_top/dut/push`: asserts only when `valid && wr_en` is high.
