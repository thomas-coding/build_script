#!/bin/bash

export PATH="/root/.toolchains/gcc-arm-none-eabi-10-2020-q4-major/bin:$PATH" 
arm-none-eabi-gdb \
    -ex 'target remote localhost:1234' \ 
    -ex '--symbols=./FreeRTOS/Demo/CORTEX_M3_MPS2_QEMU_GCC/build/RTOSDemo.axf' \ 
    -q 