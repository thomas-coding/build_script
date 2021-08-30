#!/bin/bash

# shell folder
shell_folder=$(cd "$(dirname "$0")" || exit;pwd)

workspace_dir=${shell_folder}/../../..

# toolchain
toolchains_try_dir1=~/.toolchain;
toolchains_try_dir2=${workspace_dir}/.toolchains;
toolchian=gcc-arm-none-eabi-9-2019-q4-major

#tfm_home=${shell_folder}

# get toolchain and export
function get_and_export_toolchain()
{
    echo "get_toolchain"
    if [[ -d ${toolchains_try_dir1} ]]; then
        if [[ -d ${toolchains_try_dir1}/${toolchian}/bin ]]; then
            echo "find toolchain from ${toolchains_try_dir1}"
            export PATH="${toolchains_try_dir1}/${toolchian}/bin:$PATH"
            return
        fi
    fi
    
    if [[ -d ${toolchains_try_dir2} ]]; then
        if [[ -d ${toolchains_try_dir2}/${toolchian}/bin ]]; then
            echo "find toolchain from ${toolchains_try_dir2}"
            export PATH="${toolchains_try_dir2}/${toolchian}/bin:$PATH"
            return
        fi
    fi
    echo "cann't find toolchain, please run root script './build.sh --toolchains' ,exit ...."
    exit
}

get_and_export_toolchain

# gdb
arm-none-eabi-gdb ${shell_folder}/atf/build/alius/release/bl1/bl1.elf \
-ex 'target remote localhost:1234' \
-ex "restore atf/build/alius/release/fip.bin binary 0x30200000" \
-q

