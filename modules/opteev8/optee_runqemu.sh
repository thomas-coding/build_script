#!/bin/bash

qemu_option=
if [[ $1  = "--gdb" ]]; then
    qemu_option+="run-only-gdb"
    echo "enable gdb, please run script './rungdb', and enter c "
else
    qemu_option+="run-only"
    echo "not use gdb, just run"
fi

cd build

make ${qemu_option}

