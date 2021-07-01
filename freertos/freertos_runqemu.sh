#!/bin/bash



/root/software/qemu/qemu-6.0.0/build/qemu-system-arm \
    -machine mps2-an500 -monitor null -semihosting \
    --semihosting-config enable=on,target=native \
    -kernel ./FreeRTOS/Demo/CORTEX_M3_MPS2_QEMU_GCC/build/RTOSDemo.axf \
    -serial stdio -nographic \
    -s -S