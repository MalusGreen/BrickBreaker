# Set the working dir, where all compiled Verilog goes.
vlib test

# Compile all Verilog modules in part.v to working dir;
# could also have multiple Verilog files.
# The timescale argument defines default time unit
# (used when no unit is specified), while the second number
# defines precision (all times are rounded to this value)
vlog -timescale 1ns/1ns platform.v

# Load simulation using part2 as the top level simulation module.
vsim platform

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}


force {clk} 0 0ns, 1 5ns -r 10ns

#SET UP
force {resetn} 0
force {enable} 0

force {draw} 0
force {left} 0
force {right} 0

run 10ns

force {resetn} 1

#TEST 1
force {draw} 1
force {left} 0
force {right} 0

run 10ns

force {draw} 0

run 30ns

#TEST 2
force {draw} 1
force {left} 0
force {right} 1

run 10ns

force {draw} 0

run 30ns

#TEST 3
force {draw} 1
force {left} 1
force {right} 0

run 10ns

force {draw} 0

run 30ns

#TEST RESET
force {resetn} 0
force {draw} 1
force {left} 0
force {right} 0

run 10ns

force {draw} 0

run 30ns