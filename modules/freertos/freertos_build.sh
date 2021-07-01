#!/bin/bash

export PATH="/root/.toolchains/gcc-arm-none-eabi-10-2020-q4-major/bin:$PATH"


cd ./FreeRTOS/Demo/CORTEX_M3_MPS2_QEMU_GCC
rm -rf build
make DEBUG=1

arm-none-eabi-objdump -Slg /root/code/freertos/FreeRTOS/FreeRTOS/Demo/CORTEX_M3_MPS2_QEMU_GCC/build/RTOSDemo.axf >/root/code/freertos/FreeRTOS/FreeRTOS/Demo/CORTEX_M3_MPS2_QEMU_GCC/build/RTOSDemo.objdump
