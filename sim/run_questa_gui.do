onerror {resume}

set questa_root [file normalize [file join [file dirname [info nameofexecutable]] ..]]
set uvm_src     [file join $questa_root verilog_src uvm-1.1d src]

if {[file exists work]} {
  vdel -lib work -all
}
vlib work

vlog -sv -mfcu -L mtiUvm "+incdir+$uvm_src" -f sim/files.f

# -voptargs=+acc keeps full visibility of nets/registers for waveform debug.
vsim -L mtiUvm -voptargs=+acc work.tb_top

# Record every signal in the whole hierarchy so the Wave window can show them.
log -r /*

# Add the key interfaces and the DUT internals to the Wave window.
add wave -divider "Write interface"
add wave -r /tb_top/write_if/*
add wave -divider "Read interface"
add wave -r /tb_top/read_if/*
add wave -divider "FIFO DUT"
add wave -r /tb_top/dut/*

run -all

# Zoom to show the full captured activity. Do NOT quit, so the GUI stays open.
wave zoom full
