# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all Verilog modules in mux.v to working dir;
# could also have multiple Verilog files.
# The timescale argument defines default time unit
# (used when no unit is specified), while the second number
# defines precision (all times are rounded to this value)
vlog -timescale 1ns/1ns brickbreaker.v

# Load simulation using mux as the top level simulation module.
vsim brickbreaker

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave -r {/*}

#Reset Before Test Cases
force {CLOCK_50} 0 0ns, 1 1ns -r 2ns

force {KEY} 0000
run 2ns
force {KEY} 0001
run 2ns

force {KEY[3]} 0
force {KEY[2]} 1
force {SW[9:0]} 000000000

run 2000ns