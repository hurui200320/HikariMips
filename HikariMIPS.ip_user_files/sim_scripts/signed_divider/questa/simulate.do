onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib signed_divider_opt

do {wave.do}

view wave
view structure
view signals

do {signed_divider.udo}

run -all

quit -force
