#!/bin/bash

#/home/cn1396/software/qemu/qemu-5.2.0/build/arm-softmmu/qemu-system-arm -s -S -M mps2-an521 -kernel "build/install/outputs/MPS2/AN521/tfm_s.axf" -device loader,file="build/install/outputs/MPS2/AN521/tfm_ns.bin",addr=0x00100000 -serial stdio -display none
#/home/cn1396/software/qemu/qemu-5.2.0/build/arm-softmmu/qemu-system-arm -s -S -M mps2-an521 -kernel build/bin/bl2.elf -serial stdio -display none -m 16 -pflash flash/m33_flash.bin


/root/software/qemu/qemu-6.0.0/build/qemu-system-arm \
-M mps2-an521 -kernel build/install/outputs/MPS2/AN521/tfm_s.axf \
-serial stdio -display none -m 16 \
-s -S
