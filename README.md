# SOP/EOP Packet FIFO and UVM Testbench

## 1. Project purpose

This project demonstrates a small packet-oriented RTL design and a complete UVM verification environment.

The protocol transfers one data byte, called a **beat**, on each accepted clock cycle. A packet consists of one or more beats:

- `sop` identifies the first beat of a packet.
- `eop` identifies the last beat of a packet.
- `valid` indicates that the other transfer signals are meaningful.
- `wr_en` requests an input transfer into the DUT.
- `rd_en` requests an output transfer from the DUT.

The DUT is a synchronous FIFO. It stores the data and the SOP/EOP markers for every accepted input beat, then reproduces the same packet stream at its output. The UVM testbench sends randomized packets into the FIFO and checks that the output packets have the same lengths, data, and order.

## 2. Project structure

```text
packet_protocol/
|-- rtl/
|   `-- packet_fifo.sv
|-- tb/
|   |-- uvc/
|   |   |-- packet_item.sv
|   |   |-- packet_agent_config.sv
|   |   |-- packet_sequencer.sv
|   |   |-- packet_driver.sv
|   |   |-- packet_monitor.sv
|   |   `-- packet_agent.sv
|   |-- env/
|   |   |-- packet_scoreboard.sv
|   |   `-- packet_env.sv
|   |-- sequences/
|   |   |-- packet_base_sequence.sv
|   |   `-- packet_random_sequence.sv
|   |-- tests/
|   |   |-- packet_base_test.sv
|   |   `-- packet_random_test.sv
|   |-- packet_if.sv
|   |-- packet_uvc_pkg.sv
|   `-- tb_top.sv
|-- sim/
|   |-- Makefile
|   |-- probe.tcl
|   |-- files.f
|   `-- run_questa.do
`-- ReadMe.md
```

## 3. Protocol definition

### 3.1 Signal descriptions

| Signal | DUT direction | Description |
|---|---:|---|
| `clk` | Input | Common clock. The DUT updates its FIFO state on the rising edge. |
| `rst` | Input | Active-high synchronous reset. It clears the FIFO pointers and stored-beat count. |
| `in_sop` | Input | Marks the accepted input beat as the first beat of a packet. |
| `in_eop` | Input | Marks the accepted input beat as the final beat of a packet. |
| `in_valid` | Input | Indicates that the input packet signals contain a valid beat. |
| `in_data` | Input | Input data beat. The default width is 8 bits. |
| `in_wr_en` | Input | Enables an input write transfer. |
| `out_sop` | Output | Reproduces the SOP marker stored with the current output beat. |
| `out_eop` | Output | Reproduces the EOP marker stored with the current output beat. |
| `out_valid` | Output | Indicates that the FIFO has a beat available at its output. |
| `out_data` | Output | Data from the current FIFO entry. |
| `out_rd_en` | Input | Enables consumption of the current output beat. |

The testbench interface uses the shorter names `sop`, `eop`, `valid`, `data`, `wr_en`, and `rd_en`. `tb_top.sv` maps those interface signals to the corresponding DUT input or output ports.

### 3.2 Write transfer

The DUT accepts an input beat on a rising edge when all of the following are true:

```systemverilog
in_wr_en && in_valid && (count < DEPTH)
```

The RTL calls this condition `push`.

The protocol does not include a `ready` or `full` output. The source must therefore avoid sending more beats than the FIFO can store. An assertion reports an error if `in_wr_en && in_valid` is asserted while the FIFO is full.

### 3.3 Read transfer

The DUT consumes its current output beat on a rising edge when:

```systemverilog
out_rd_en && out_valid
```

The RTL calls this condition `pop`.

`out_valid` is high whenever the FIFO contains at least one beat. When the FIFO is empty, `out_valid`, `out_sop`, and `out_eop` are low, and `out_data` is zero.

### 3.4 SOP and EOP rules

A legal packet follows these rules:

1. Its first accepted beat has `sop = 1`.
2. Intermediate beats have `sop = 0` and `eop = 0`.
3. Its final accepted beat has `eop = 1`.
4. A one-beat packet has both `sop = 1` and `eop = 1` on the same transfer.
5. SOP and EOP are meaningful only during an accepted transfer.

Example three-byte input packet:

```text
Rising edge       1       2       3
                 ---     ---     ---
wr_en             1       1       1
valid             1       1       1
sop               1       0       0
eop               0       0       1
data             0x12    0x34    0x56
                 first   middle  last
```

## 4. RTL design

### `rtl/packet_fifo.sv`

`packet_fifo` is a parameterized synchronous FIFO that stores complete packet beats.

### 4.1 Parameters

```systemverilog
parameter int DATA_WIDTH = 8;
parameter int DEPTH      = 64;
```

- `DATA_WIDTH` controls the number of data bits in one beat.
- `DEPTH` controls the number of beats the FIFO can hold. It is a beat count, not a packet count. For example, four packets of four bytes each occupy 16 entries.

The supplied UVM transaction and monitors use fixed 8-bit payload elements. The default `DATA_WIDTH = 8` must therefore be used unless the UVM classes are also updated.

### 4.2 Stored FIFO entry

Each memory entry stores the two packet markers along with the data:

```systemverilog
typedef logic [DATA_WIDTH+1:0] beat_t;
beat_t mem [DEPTH];
```

The packed entry is written as:

```systemverilog
{in_sop, in_eop, in_data}
```

The bit positions are therefore:

```text
DATA_WIDTH+1          DATA_WIDTH          DATA_WIDTH-1:0
+------------------+------------------+-------------------+
| SOP              | EOP              | data              |
+------------------+------------------+-------------------+
```

Storing SOP and EOP with every beat allows the output to reproduce packet boundaries exactly.

### 4.3 FIFO state

The DUT maintains:

- `wr_ptr`: address at which the next accepted input beat is stored.
- `rd_ptr`: address of the current output beat.
- `count`: number of beats currently stored.

`PTR_WIDTH` is calculated with `$clog2(DEPTH)`. A minimum width of one bit is used when `DEPTH <= 1`.

### 4.4 Combinational output path

The current entry at `mem[rd_ptr]` drives the output whenever `count != 0`:

```systemverilog
out_valid = (count != 0);
out_sop   = out_valid ? mem[rd_ptr][DATA_WIDTH+1]   : 1'b0;
out_eop   = out_valid ? mem[rd_ptr][DATA_WIDTH]     : 1'b0;
out_data  = out_valid ? mem[rd_ptr][DATA_WIDTH-1:0] : '0;
```

The output remains stable at the current entry until a read transfer advances `rd_ptr`.

### 4.5 Sequential behavior

All state changes occur on `posedge clk`.

During reset:

```systemverilog
wr_ptr <= '0;
rd_ptr <= '0;
count  <= '0;
```

The memory itself is not reset because its contents are ignored while `count == 0`.

During normal operation:

- A `push` writes `{in_sop, in_eop, in_data}` and advances `wr_ptr`.
- A `pop` advances `rd_ptr`.
- Push without pop increments `count`.
- Pop without push decrements `count`.
- Simultaneous push and pop leave `count` unchanged.
- Neither operation leaves the state unchanged.

Both pointers explicitly wrap to zero at `DEPTH-1`.

### 4.6 RTL assertions

The DUT contains three SystemVerilog assertions:

#### `a_no_write_when_full`

Reports an overflow attempt when the source asserts `in_wr_en && in_valid` while `count == DEPTH`.

#### `a_sop_is_valid`

Requires every asserted input SOP marker to occur with `in_wr_en && in_valid`.

#### `a_eop_is_valid`

Requires every asserted input EOP marker to occur with `in_wr_en && in_valid`.

These assertions check beat-level signal usage. The UVM monitors perform the packet-level checks, such as detecting data before SOP or a second SOP before EOP.

## 5. UVM architecture

```text
packet_random_test
`-- packet_env
    |-- write_agent                         [UVM_ACTIVE]
    |   |-- sequencer
    |   |-- driver ------ write_if ------> packet_fifo
    |   `-- monitor ---- expected packet ----\
    |                                         \
    |                                          > scoreboard
    |                                         /
    `-- read_agent                           /
        `-- monitor <---- read_if <--------- packet_fifo
                     actual packet
```

Both `write_agent` and `read_agent` are instances of the same `packet_agent` class. Their `packet_agent_config` objects select different behavior:

- `write_agent`: `UVM_ACTIVE` and `PACKET_WRITE_SIDE`. It creates a sequencer, driver, and shared monitor.
- `read_agent`: `UVM_PASSIVE` and `PACKET_READ_SIDE`. It creates only the shared monitor.

The monitor uses the role enum to sample `wr_en && valid` on the write side or `rd_en && valid` on the read side. Since the passive read instance cannot drive `rd_en`, `tb_top.sv` ties it high. The FIFO output is consumed whenever `out_valid` is high.

The scoreboard compares complete packets in FIFO order. It does not predict internal FIFO cycle timing; it checks packet content and ordering.

## 6. Testbench files in execution order

The following sections start with the transaction object and proceed through the top-level testbench.

### 6.1 Transaction: `tb/uvc/packet_item.sv`

```systemverilog
class packet_item extends uvm_sequence_item;
```

`packet_item` represents one complete packet at the UVM transaction level. It does not represent one clock-cycle beat.

#### Payload

```systemverilog
rand bit [7:0] payload[];
```

`payload` is a randomized dynamic array of bytes. Each array element becomes one protocol beat. A dynamic array allows every packet to have a different length.

#### Length constraint

```systemverilog
constraint c_packet_length {
  payload.size() inside {[1:8]};
}
```

Every randomized packet contains between one and eight bytes. The lower bound prevents an empty packet. A one-byte packet causes the driver to assert SOP and EOP together.

#### Factory and field registration

`uvm_object_utils_begin` registers the transaction with the UVM factory. `uvm_field_array_int` enables standard operations such as `clone()`, `copy()`, `compare()`, `print()`, and `sprint()` for the payload array.

The scoreboard depends on this registration when it clones expected packets.

#### `compare_packet()`

This custom comparison function:

1. Rejects a null actual packet.
2. Compares packet lengths.
3. Compares every byte in order with case inequality (`!==`).
4. Returns a readable failure reason identifying a length mismatch or the first mismatched byte.

The scoreboard uses this method instead of relying only on the default UVM comparer so that failures have protocol-specific messages.

### 6.2 Sequencer: `tb/uvc/packet_sequencer.sv`

```systemverilog
class packet_sequencer extends uvm_sequencer #(packet_item);
```

The sequencer arbitrates packet transactions and passes them from a sequence to the driver. This skeleton uses one sequence, so no complex arbitration policy is required.

The parameter `packet_item` enforces the transaction type accepted by both the sequencer and driver.

### 6.3 Sequences

#### Base sequence: `tb/sequences/packet_base_sequence.sv`

```systemverilog
class packet_base_sequence extends uvm_sequence #(packet_item);
```

`packet_base_sequence` holds behavior shared by all packet stimulus scenarios:

- `packet_count`, which defaults to ten packets and can control scenario loops.
- `packets_sent`, which counts items completed through the base send helpers.
- `send_packet()`, which sends an item that a derived sequence has already configured.
- `send_random_packet()`, which creates, randomizes, and sends one `packet_item`.

The base sequence handles the `start_item()`/`finish_item()` handshake and common error checking. It intentionally has no `body()` implementation; each derived sequence defines its own scenario.

A directed sequence can reuse it as follows:

```systemverilog
class packet_single_byte_sequence extends packet_base_sequence;
  `uvm_object_utils(packet_single_byte_sequence)

  function new(string name = "packet_single_byte_sequence");
    super.new(name);
  endfunction

  task body();
    packet_item item;
    item = packet_item::type_id::create("item");
    item.payload = new[1];
    item.payload[0] = 8'hA5;
    send_packet(item);
  endtask
endclass
```

#### Random sequence: `tb/sequences/packet_random_sequence.sv`

```systemverilog
class packet_random_sequence extends packet_base_sequence;
```

The random sequence inherits `packet_count` and the send helpers. Its `body()` calls `send_random_packet()` once per requested packet:

```systemverilog
for (int unsigned i = 0; i < packet_count; i++)
  send_random_packet($sformatf("item_%0d", i));
```

Each item uses the `packet_item` constraints, so every generated packet contains between one and eight randomized bytes. The scenario-specific class remains short because the base sequence owns the reusable transaction handshake.

### 6.4 Driver: `tb/uvc/packet_driver.sv`

```systemverilog
class packet_driver extends uvm_driver #(packet_item);
```

The driver converts each packet transaction into cycle-level interface activity.

#### Virtual interface

```systemverilog
virtual packet_if vif;
```

A class cannot connect directly to module signals. The virtual interface gives the driver a handle to the `packet_if` instance created in `tb_top`.

During `build_phase`, the driver retrieves the handle from `uvm_config_db`. Missing configuration produces `UVM_FATAL`, because the driver cannot operate without the interface.

#### `run_phase()`

The driver first initializes all write-side outputs to inactive values:

```text
sop=0, eop=0, valid=0, data=0, wr_en=0
```

It then repeats the UVM driver handshake forever:

1. `get_next_item(req)` receives one packet from the sequencer.
2. `drive_packet(req)` serializes the packet onto the interface.
3. `item_done()` tells the sequencer that the request has completed.

#### `drive_packet()`

The driver waits while reset is asserted. It then drives one array element per clock cycle.

Signals are changed on `negedge clk`. The DUT samples them on the following `posedge clk`, which avoids a race between the testbench driver and the synchronous RTL.

For payload element `i`:

```systemverilog
sop = (i == 0);
eop = (i == payload.size()-1);
valid = 1;
wr_en = 1;
data = payload[i];
```

After the final byte, the driver waits for the next falling edge and returns all write controls and data to inactive values. This creates one idle cycle between generated packets.

### 6.5 Interface: `tb/packet_if.sv`

```systemverilog
interface packet_if #(parameter int DATA_WIDTH = 8) (input logic clk);
```

The interface bundles all packet protocol signals:

```text
rst, sop, eop, valid, data, rd_en, wr_en
```

`tb_top` creates two instances:

- `write_if` connects the active driver and write monitor to the DUT input.
- `read_if` connects the DUT output to the passive read monitor.

#### Monitor clocking block

```systemverilog
clocking mon_cb @(posedge clk);
  default input #1step;
  ...
endclocking
```

Both monitors sample through `mon_cb`. The `#1step` input skew samples values immediately before the rising edge. These are the values the DUT uses for that edge, which avoids races with RTL nonblocking assignments.

The driver does not use a clocking block. It drives directly at the falling edge, half a clock period before DUT sampling.

### 6.6 Agent configuration: `tb/uvc/packet_agent_config.sv`

`packet_agent_config` configures one `packet_agent` instance. It contains:

- `is_active`: UVM's `UVM_ACTIVE` or `UVM_PASSIVE` enum. The agent copies this value into its inherited `uvm_agent.is_active` field, so `get_is_active()` and UVM topology/introspection agree.
- `role`: `PACKET_WRITE_SIDE` or `PACKET_READ_SIDE`.
- `vif`: the physical `packet_if` used by that instance.

Activity and role are separate decisions. Activity controls which components the agent creates. Role controls which transfer enable the shared monitor observes.

### 6.7 Shared monitor: `tb/uvc/packet_monitor.sv`

Both agent instances create the same `packet_monitor` class. The monitor gets `packet_agent_config` from `uvm_config_db` and samples through `cfg.vif.mon_cb`.

The role selects the transfer condition:

```systemverilog
if (cfg.role == PACKET_WRITE_SIDE)
  transfer = cfg.vif.mon_cb.wr_en && cfg.vif.mon_cb.valid;
else
  transfer = cfg.vif.mon_cb.rd_en && cfg.vif.mon_cb.valid;
```

After detecting a transfer, the monitor uses shared SOP/EOP reconstruction logic:

1. SOP creates an empty `packet_item` and starts collection.
2. Each transferred data byte is appended to the payload.
3. EOP publishes the complete packet through `ap`.
4. Nested SOP or a beat without a preceding SOP produces a role-specific protocol error.
5. Reset discards any partially collected packet.

The environment connects the write-agent monitor to the expected scoreboard input and the read-agent monitor to the actual scoreboard input.

### 6.8 Agent: `tb/uvc/packet_agent.sv`

The file defines one reusable `packet_agent` class. Every instance retrieves a `packet_agent_config` and always creates `packet_monitor`.

When `get_is_active() == UVM_ACTIVE`, the agent also creates `packet_sequencer` and `packet_driver`, then connects:

```text
driver.seq_item_port -> sequencer.seq_item_export
```

When `cfg.is_active == UVM_PASSIVE`, the sequencer and driver are not created. The current driver supports only `PACKET_WRITE_SIDE`; an active read-side configuration produces a fatal configuration error rather than driving the wrong signals.

### 6.9 Scoreboard: `tb/env/packet_scoreboard.sv`

The scoreboard compares expected input packets against actual output packets in order.

#### Two analysis implementations

A scoreboard needs separate callback methods for expected and actual traffic. These macros create two implementation classes:

```systemverilog
`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)
```

The scoreboard then declares:

```systemverilog
uvm_analysis_imp_expected #(packet_item, packet_scoreboard) expected_export;
uvm_analysis_imp_actual   #(packet_item, packet_scoreboard) actual_export;
```

Calls arriving at `expected_export` invoke `write_expected()`. Calls arriving at `actual_export` invoke `write_actual()`.

#### Expected queue

```systemverilog
packet_item expected_queue[$];
```

A SystemVerilog queue preserves FIFO packet order. `write_expected()` clones each packet before storing it so later changes to the monitor's object cannot alter the scoreboard reference data.

#### Actual comparison

`write_actual()`:

1. Reports an unexpected-output error if no expected packet is queued.
2. Removes the oldest expected packet with `pop_front()`.
3. Calls `expected.compare_packet(actual, reason)`.
4. Reports a detailed `UVM_ERROR` on mismatch.
5. Reports a match at `UVM_MEDIUM` verbosity on success.
6. Increments `compared_packets`.

#### End-of-test checks

In `check_phase`, the scoreboard reports an error if expected packets remain. Such entries mean that the input monitor observed packets that never appeared completely at the output.

In `report_phase`, it prints the total number of compared packets.

### 6.10 Environment: `tb/env/packet_env.sv`

```systemverilog
class packet_env extends uvm_env;
```

The environment creates the complete verification structure:

- `write_agent`
- `read_agent`
- `scoreboard`

During `connect_phase` it establishes the analysis paths:

```systemverilog
write_agent.monitor.ap.connect(scoreboard.expected_export);
read_agent.monitor.ap.connect(scoreboard.actual_export);
```

No direct connection exists between the driver and scoreboard. Both expected and actual streams come from interface monitors.

### 6.11 Tests

#### Base test: `tb/tests/packet_base_test.sv`

```systemverilog
class packet_base_test extends uvm_test;
```

`packet_base_test` owns the common testbench setup. Its `build_phase()` retrieves `write_vif` and `read_vif`, creates the two `packet_agent_config` objects, and creates `packet_env`.

The write configuration selects `UVM_ACTIVE` with `PACKET_WRITE_SIDE`. The read configuration selects `UVM_PASSIVE` with `PACKET_READ_SIDE`. Both environment children are instances of the same `packet_agent` class.

The reusable `run_packet_sequence()` task:

1. Rejects a null sequence.
2. Saves the scoreboard comparison count before the sequence starts.
3. Raises the run-phase objection.
4. Starts the sequence on `env.write_agent.sequencer`.
5. Uses the sequence's `packets_sent` count to calculate the incremental scoreboard target.
6. Waits until the scoreboard reaches that target.
7. Drops the objection.

Using the observed `packets_sent` value allows a derived sequence to send any number of packets through `send_packet()` and `send_random_packet()` without separately synchronizing an expected count. It also allows a derived test to call `run_packet_sequence()` more than once.

#### Random test: `tb/tests/packet_random_test.sv`

```systemverilog
class packet_random_test extends packet_base_test;
```

The random test inherits the environment and execution helper. Its `run_phase()` creates `packet_random_sequence`, sets `packet_count` to ten, and passes the sequence to `run_packet_sequence()`.

New tests should normally extend `packet_base_test`, create one or more classes derived from `packet_base_sequence`, and run them through the inherited helper. A missing output packet prevents the scoreboard target from being reached; the top-level timeout then terminates the test instead of allowing it to hang indefinitely.

### 6.12 Package: `tb/packet_uvc_pkg.sv`

`packet_uvc_pkg` imports UVM, includes the UVM macros, and compiles all classes into one package.

The include order follows class dependencies:

1. Transaction item
2. Agent role enum and configuration object
3. Sequencer
4. Driver
5. Shared monitor
6. Configurable agent
7. Scoreboard
8. Environment
9. Base sequence
10. Derived random sequence
11. Base test
12. Derived random test

`tb_top.sv` imports this package to make `packet_random_test` and all supporting types available.

### 6.13 Top-level testbench: `tb/tb_top.sv`

`tb_top` connects the static RTL world to the class-based UVM world.

#### Clock

```systemverilog
logic clk = 1'b0;
always #5 clk = ~clk;
```

With `` `timescale 1ns/1ps ``, this creates a 10 ns period, 100 MHz clock.

#### Interface instances

```systemverilog
packet_if #(DATA_WIDTH) write_if(clk);
packet_if #(DATA_WIDTH) read_if(clk);
```

Both interfaces share the same clock. The write interface carries DUT input traffic, while the read interface carries DUT output traffic.

#### DUT instance

The top sets:

```text
DATA_WIDTH = 8
FIFO_DEPTH = 64 beats
```

It maps the write interface to `in_*` DUT ports and the read interface to `out_*` DUT ports.

#### Passive read behavior

```systemverilog
assign read_if.rd_en = 1'b1;
```

The passive read agent cannot drive protocol signals, so the harness permanently enables reads. Whenever the DUT asserts output valid, that beat is consumed on the next rising edge.

Unused directional signals are held low:

```systemverilog
assign read_if.wr_en  = 1'b0;
assign write_if.rd_en = 1'b0;
```

#### Reset

`write_if.rst` starts high, remains asserted for five rising clock edges, and is then deasserted. `read_if.rst` is continuously connected to the same reset.

Because the DUT reset is synchronous, reset takes effect on rising edges while `rst` is high.

#### Virtual-interface and agent configuration

Before calling `run_test`, the top stores the physical interface handles for `packet_base_test`:

```text
write_if -> uvm_test_top.write_vif
read_if  -> uvm_test_top.read_vif
```

The base test creates:

```text
write_cfg = UVM_ACTIVE  + PACKET_WRITE_SIDE + write_vif
read_cfg  = UVM_PASSIVE + PACKET_READ_SIDE  + read_vif
```

It publishes each `packet_agent_config` to the corresponding environment agent. Each agent then supplies its configuration to its shared monitor and, for the active write instance, its driver.

#### Starting UVM

```systemverilog
run_test("packet_random_test");
```

This asks the UVM factory to create and run `packet_random_test`.

#### Timeout

A 10 microsecond timeout issues `UVM_FATAL` if the test does not finish. Normal random-test execution completes in well under this limit.

## 7. End-to-end packet flow

For one randomized packet, the complete flow is:

1. `packet_random_sequence` creates and randomizes a `packet_item`.
2. `packet_sequencer` makes the item available to `packet_driver`.
3. The driver receives the item with `get_next_item()`.
4. The driver presents one payload byte per cycle on `write_if`.
5. On every rising edge with `wr_en && valid`, the DUT stores `{sop, eop, data}`.
6. The `PACKET_WRITE_SIDE` instance of `packet_monitor` observes the same input transfers and rebuilds the expected packet.
7. On input EOP, that monitor sends the expected packet to the scoreboard.
8. Because `read_if.rd_en` is high, the DUT emits and consumes stored beats whenever its output is valid.
9. The `PACKET_READ_SIDE` instance of `packet_monitor` observes `rd_en && valid` and rebuilds the actual packet.
10. On output EOP, that monitor sends the actual packet to the scoreboard.
11. The scoreboard removes the oldest expected packet and compares its length and every byte against the actual packet.
12. After ten comparisons, the test drops its objection. UVM executes `check_phase` and `report_phase`, prints its summary, and ends simulation.

## 8. Build and simulation files

### `sim/files.f`

The file list provides the required source compilation order:

```text
+incdir+tb
rtl/packet_fifo.sv
tb/packet_if.sv
tb/packet_uvc_pkg.sv
tb/tb_top.sv
```

The package includes the individual class files, so those files do not need separate entries in the file list.

### `sim/run_questa.do`

The Questa script:

1. Configures Tcl command and break errors to exit with status 1.
2. Locates the Questa installation and its UVM 1.1d source headers.
3. Deletes and recreates the local `work` library.
4. Compiles all files as SystemVerilog with `vlog`.
5. Links against the precompiled `mtiUvm` library.
6. Elaborates `work.tb_top` in command-line mode.
7. Runs until UVM calls `$finish` or the top-level timeout occurs.

## 9. Running the test

### Prerequisites

- QuestaSim with the `mtiUvm` precompiled UVM 1.1d library.
- `vlog` and `vsim` available on the command path.
- Run the command from the project root, where `rtl`, `tb`, and `sim` are direct subdirectories.

### Command-line run

```powershell
vsim -c -do sim/run_questa.do
```

A successful run includes messages similar to:

```text
[SCOREBOARD] Packet 0 matched
...
[SCOREBOARD] Packet 9 matched
[SCOREBOARD] Compared 10 packet(s)

UVM_WARNING : 0
UVM_ERROR   : 0
UVM_FATAL   : 0
```

The generated `work` directory, `transcript`, and ModelSim/Questa initialization files are simulation artifacts, not design source.

## 10. Expected UVM hierarchy

The important runtime hierarchy is:

```text
uvm_test_top                         packet_random_test (extends packet_base_test)
`-- env                              packet_env
    |-- write_agent                  packet_agent
    |   |-- sequencer                packet_sequencer
    |   |-- driver                   packet_driver
    |   `-- monitor                  packet_monitor
    |-- read_agent                   packet_agent
    |   `-- monitor                  packet_monitor
    `-- scoreboard                   packet_scoreboard
```

## 11. Current scope and extension points

This project is intentionally a compact verification skeleton. Its current scope is:

- One clock domain
- Active-high synchronous reset
- Eight-bit UVM packet data
- One to eight bytes per generated packet
- In-order FIFO behavior
- Continuously enabled output reads
- No input `ready` or FIFO `full` signal
- No randomized idle cycles inside a packet
- No randomized output backpressure
- No functional coverage model

Common extensions include:

1. Add `full` or `ready` to prevent overflow through a handshake.
2. Add a read driver and sequencer to randomize `rd_en` backpressure.
3. Add sequence controls for packet length, packet count, fixed data, and idle cycles.
4. Add functional coverage for packet lengths, one-beat packets, SOP/EOP positions, FIFO occupancy, simultaneous push/pop, and pointer wraparound.
5. Add reset-during-packet tests.
6. Add directed overflow and underflow tests if the DUT interface is extended to expose status.
7. Parameterize the UVM transaction and components if data widths other than eight bits are required.

## 12. Key points for new readers

- A `packet_item` is a complete packet; an RTL FIFO entry is one packet beat.
- Both `write_agent` and `read_agent` instantiate the same `packet_agent` class.
- `packet_agent_config.is_active` controls whether the sequencer and driver are created.
- `packet_agent_config.role` controls whether the monitor samples write or read transfers.
- The driver serializes one transaction into several clock cycles.
- SOP and EOP are stored in the FIFO with each data beat.
- The write monitor generates expected packets from observed input traffic.
- The read monitor generates actual packets from observed output traffic.
- The scoreboard compares packets in FIFO order.
- The write agent is active; the read agent is passive.
- `tb_top` ties `rd_en` high because the passive read agent cannot drive it.
- The test ends only after all ten packets have been compared or the timeout occurs.

## 13. Xcelium and SimVision waveform recording

### `sim/Makefile`

The Xcelium Makefile compiles the RTL, interface, UVM package, and top module in dependency order. Both `run` and `gui` pass `sim/probe.tcl` to Xcelium with the `-input` option. The Makefile already uses `-access +rwc`, which preserves read, write, and connectivity access to elaborated HDL objects.

Run Xcelium from the project root with:

```bash
make -C sim run
```

This creates the waveform database at:

```text
sim/waves.shm
```

To compile, run, and open the live SimVision GUI, use:

```bash
make -C sim gui
```

### `sim/probe.tcl`

The probe script contains:

```tcl
database -open waves -shm -into waves.shm -default
probe -create tb_top -database waves -all -depth all
run
```

The commands perform these operations:

1. `database -open` creates an SHM database named `waves` in `waves.shm`.
2. `-default` makes it the default destination for recorded probes.
3. `probe -create tb_top` selects the HDL top-level instance.
4. `-all` records all supported objects in each selected scope.
5. `-depth all` recursively records all descendants of `tb_top`.
6. `run` starts simulation only after the probes are active.

The recursive probe records the important HDL scopes:

```text
tb_top
|-- clk
|-- write_if
|   |-- rst
|   |-- sop
|   |-- eop
|   |-- valid
|   |-- data
|   |-- wr_en
|   `-- rd_en
|-- read_if
|   |-- rst
|   |-- sop
|   |-- eop
|   |-- valid
|   |-- data
|   |-- wr_en
|   `-- rd_en
`-- dut
    |-- input and output packet ports
    |-- push and pop
    |-- wr_ptr and rd_ptr
    |-- count
    `-- FIFO memory, when supported by the selected SimVision view
```

### Opening the recorded database

After `make -C sim run`, open the database from the project root:

```bash
simvision sim/waves.shm &
```

Alternatively, enter the simulation directory first and use:

```bash
cd sim
simvision waves.shm &
```

In the SimVision Design Browser, expand `waves`, then expand `tb_top`. Select `write_if`, `read_if`, or `dut`, select the required signals in the object list, and send them to the waveform window.

If the browser shows only `UVM` and `trans_global`, the opened SHM database was generated before HDL probes were enabled or the wrong database was opened. Remove the old simulation output and rerun:

```bash
make -C sim clean
make -C sim run
simvision sim/waves.shm &
```

An existing SHM database cannot display signals that were not recorded during its simulation. It must be regenerated after adding or changing probes.

### Database size

`-all -depth all` is appropriate for this small project and makes debugging easy. For a large design, it can produce a large SHM database. In that case, replace the single recursive probe with focused probes for `tb_top.clk`, `tb_top.write_if`, `tb_top.read_if`, and `tb_top.dut`.
