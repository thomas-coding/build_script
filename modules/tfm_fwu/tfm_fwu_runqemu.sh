#!/bin/bash

cd qemu-tfm || exit
#./runqemu.sh

qemu_option=
if [[ $1  = "--gdb" ]]; then
    qemu_option+=" -s -S"
    echo "enable gdb, please run script './rungdb', and enter c "
else
    echo "not use gdb, just run"
fi


qemu_option+=" -machine mps2-an521 -cpu cortex-m33"
qemu_option+=" -kernel ../tfm-fwu/cmake_build/install/outputs/MPS2/AN521/bl2.elf"
qemu_option+=" -m 16 -nographic"

# run qemu
./build/qemu-system-arm ${qemu_option}
