#!/bin/bash

shell_folder=$(cd "$(dirname "$0")" || exit;pwd)

build_home=${shell_folder}/build
tfm_home=${shell_folder}/trusted-firmware-m


# toolchain
toolchains_try_dir1=~/.toolchains;
toolchains_try_dir2=${workspace_dir}/.toolchain;
toolchian=gcc-arm-none-eabi-9-2019-q4-major

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

rm -rf "${shell_folder}"/out
# Build TFM
cd "${tfm_home}" || exit
rm -rf build

cd "${build_home}" || exit
./build.sh alius tfm

# Build freertos
cd "${build_home}" || exit
./build.sh alius freertos

cd "${tfm_home}/build/bin" || exit
arm-none-eabi-objdump -Slg tfm_s.elf > tfm_s.objdump
