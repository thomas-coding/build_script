#!/bin/bash

cd qemu-tfm
#./runqemu.sh

./build/qemu-system-arm \
-machine mps2-an521 \
-cpu cortex-m33 \
-kernel ../tfm-fwu/cmake_build/install/outputs/MPS2/AN521/bl2.elf \
-m 16 -nographic \
-s -S