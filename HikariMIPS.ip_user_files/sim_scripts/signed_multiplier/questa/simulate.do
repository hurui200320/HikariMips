onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib signed_multiplier_opt

do {wave.do}

view wave
view structure
view signals

do {signed_multiplier.udo}

run -all

quit -force
