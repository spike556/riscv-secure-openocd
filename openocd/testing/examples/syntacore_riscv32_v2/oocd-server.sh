#!/bin/bash

# interfaces
OCD_CFG_OLIMEX_USB_OCD=interface/ftdi/olimex-arm-usb-ocd.cfg
OCD_CFG_OLIMEX_USB_OCD_H=interface/ftdi/olimex-arm-usb-ocd-h.cfg
# targets
TAP_SUFFIX_UP=
TAP_SUFFIX_SMP=_2tap

# select interface and target type
OCD_IFACE=${OCD_CFG_OLIMEX_USB_OCD}
TAP_SUFFIX=${TAP_SUFFIX_UP}

# check OOCD path
if [ -z ${OOCD_ROOT} ] ; then
    echo "Environment (OOCD_ROOT) is not configured."
    exit 1
fi

OCD_TARGET=target/syntacore_riscv32_v2${TAP_SUFFIX}.cfg

echo -------------------------------------------------
echo Target   : $OCD_TARGET
echo Interface: $OCD_IFACE
echo -------------------------------------------------

bash -c "${OOCD_ROOT}/src/openocd -s ${OOCD_ROOT}/tcl -f ${OCD_IFACE} -f ${OCD_TARGET}"
