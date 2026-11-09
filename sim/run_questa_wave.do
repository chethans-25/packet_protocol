onerror {quit -code 1}
onbreak {quit -code 1}

set questa_root [file normalize [file join [file dirname [info nameofexecutable]] ..]]
set uvm_src     [file join $questa_root verilog_src uvm-1.1d src]

if {[file exists work]} {
  vdel -lib work -all
}
vlib work

vlog -sv -mfcu -L mtiUvm "+incdir+$uvm_src" -f sim/files.f

# Batch run (no GUI), but keep full signal visibility and record a WLF file.
vsim -c -L mtiUvm -voptargs=+acc -wlf packet.wlf work.tb_top -do {
  log -r /*
  run -all
  quit -code 0
}
