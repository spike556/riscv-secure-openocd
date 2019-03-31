./src/openocd \
-f ./tcl/interface/ftdi/olimex-arm-usb-tiny-h.cfg \
-f ./tcl/target/syntacore_riscv32_v2.cfg \
|& tee ocd.log
