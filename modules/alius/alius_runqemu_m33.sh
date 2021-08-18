#!/bin/bash

qemu_option=
if [[ $1  = "--gdb" ]]; then
    qemu_option+=" -s -S"
    echo "enable gdb, please run script './rungdb', and enter c "
else
    echo "not use gdb, just run"
fi

#qemu_option+=" -kernel trusted-firmware-m/build/bin/tfm_s.axf"
#qemu_option+=" -device loader,file=freertos/FreeRTOS/project/alius_m33/alius_m33_fr.bin,addr=0x20440000"

qemu_option+=" -machine alius-las"
qemu_option+=" -kernel trusted-firmware-m/build/bin/tfm_s.axf"
qemu_option+=" -device loader,file=freertos/FreeRTOS/project/alius_m33/build/m33_fr.bin,addr=0x20500000"
qemu_option+=" -nographic -monitor telnet:127.0.0.1:5432,server,nowait"

# run qemu
/home/cn1396/workspace/code/alius_csd/qemu/build/qemu-system-arm ${qemu_option}

