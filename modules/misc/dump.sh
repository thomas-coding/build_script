#!/bin/bash

# shell folder
shell_folder=$(cd "$(dirname "$0")" || exit;pwd)

export PATH="/root/workspace/.toolchains/gcc-arm-10.3-2021.07-x86_64-arm-none-eabi/bin/:$PATH"
export PATH="/home/cn1396/.toolchain/gcc-arm-10.3-2021.07-x86_64-arm-none-eabi/bin/:$PATH"

mkdir -p dump
rm -rf dump/*
arm-none-eabi-objdump -xd ${shell_folder}/out/alius_hp_size_optimized/obj/freertos/FreeRTOS/project/alius_hp/bin/alius_hp_elf.elf  > ${shell_folder}/dump/alius_hp.asm
arm-none-eabi-objdump -xd ${shell_folder}/out/alius_lp_size_optimized/obj/freertos/FreeRTOS/project/alius_lp/bin/alius_lp_elf.elf  > ${shell_folder}/dump/alius_lp.asm
