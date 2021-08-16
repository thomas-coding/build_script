#!/bin/bash

qemu_option=
if [[ $1  = "--gdb" ]]; then
    qemu_option+=" -s -S"
    echo "enable gdb, please run script './rungdb', and enter c "
else
    echo "not use gdb, just run"
fi

qemu_option+=" -machine alius-las"
qemu_option+=" -kernel baremetal-m33/output/alius-bm-s.elf"
qemu_option+=" -device loader,file=baremetal-m33/output/alius-bm-ns.bin,addr=0x20440000"
qemu_option+=" -nographic -monitor telnet:127.0.0.1:5432,server,nowait"

# run qemu
./qemu/build/qemu-system-arm ${qemu_option}

