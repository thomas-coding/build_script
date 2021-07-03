#!/bin/bash

# shell folder
shell_folder=$(cd "$(dirname "$0")";pwd)

# toolchain
toolchains_try_dir1=~/.toolchains;
toolchains_try_dir2=~/.toolchain;
toolchian=gcc-arm-none-eabi-10-2020-q4-major

# which demo to compile
demo_dir=${shell_folder}/FreeRTOS/Demo/CORTEX_M3_MPS2_QEMU_GCC

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

# build
cd ${demo_dir}
rm -rf build
make DEBUG=1

# objdump
arm-none-eabi-objdump -Slg ${demo_dir}/build/RTOSDemo.axf \
> ${demo_dir}/build/RTOSDemo.objdump