#!/bin/bash

#--symbols=linux/vmlinux
#--symbols=trusted-firmware-a/build/qemu/debug/bl31/bl31.elf
#--symbols=optee_os/out/arm/core/tee.elf
# add-symbol-file optee_os/out/arm/ldelf/ldelf.elf
# ./toolchains/aarch32/bin/arm-linux-gnueabihf-gdb \
./toolchains/aarch64/bin/aarch64-linux-gnu-gdb \
-ex 'target remote localhost:1234' \
-ex 'add-symbol-file trusted-firmware-a/build/qemu/debug/bl1/bl1.elf' \
-ex 'add-symbol-file trusted-firmware-a/build/qemu/debug/bl2/bl2.elf' \
-ex 'add-symbol-file trusted-firmware-a/build/qemu/debug/bl31/bl31.elf' \
-ex 'add-symbol-file optee_os/out/arm/core/tee.elf' \
-ex 'add-symbol-file optee_os/out/arm/ldelf/ldelf.elf' \
-ex 'add-symbol-file linux/vmlinux' \
-q \

