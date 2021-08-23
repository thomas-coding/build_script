#!/bin/bash

shell_folder=$(cd "$(dirname "$0")" || exit;pwd)

qemu_option=
if [[ $1  = "--gdb" ]]; then
    qemu_option+=" -s -S"
    echo "enable gdb, please run script './rungdb', and enter c "
else
    echo "not use gdb, just run"
fi

#qemu_option+=" -kernel trusted-firmware-m/build/bin/tfm_s.axf"
#qemu_option+=" -device loader,file=freertos/FreeRTOS/project/alius_m33/alius_m33_fr.bin,addr=0x20440000"
#qemu_option+=" -drive if=sd,file=${shell_folder}/uboot/u-boot.bin,format=raw"

qemu_option+=" -bios ${shell_folder}/atf/build/alius/release/bl1.bin"
qemu_option+=" -M alius,secure=on,virtualization=on,gic-version=3,hetero=off -cpu cortex-a32 -smp 1 -m 1024M"
qemu_option+=" -nographic -monitor telnet:127.0.0.1:6666,server,nowait -s"


# run qemu
/home/cn1396/workspace/code/alius_a32_qemu/qemu/build/qemu-system-arm ${qemu_option}

