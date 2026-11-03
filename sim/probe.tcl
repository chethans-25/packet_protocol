# Create an SHM waveform database and record the complete HDL hierarchy.
# The run command executes the simulation after all probes are active.
database -open waves -shm -into waves.shm -default
probe -create tb_top -database waves -all -depth all
run
