#!/bin/bash

#--symbols=build/bin/tfm_s.elf \
/root/.toolchains/gcc-arm-none-eabi-9-2019-q4-major/bin/arm-none-eabi-gdb -ex 'target remote localhost:1234' \
--symbols=freertos-tfm-fwu/freertos_kernel/portable/ThirdParty/GCC/ARM_CM33_TFM/build/RTOSDemo.axf \
-q \

