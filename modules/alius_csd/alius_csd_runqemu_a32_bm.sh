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

qemu_option=
if [[ $1  = "--gdb" ]]; then
    qemu_option+=" -s -S"
    echo "enable gdb, please run script './rungdb', and enter c "
else
    echo "not use gdb, just run"
fi

qemu_option+=" -kernel baremetal-a32/output/lps/alius-bm-lps.elf"
qemu_option+=" -M alius,secure=on,virtualization=on,gic-version=3,hetero=off -cpu cortex-a32 -smp 1 -m 1024M"
qemu_option+=" -nographic -monitor telnet:127.0.0.1:6666,server,nowait"

# run qemu
#gdb --args  
/home/cn1396/workspace/code/alius_a32_qemu/qemu/build/qemu-system-arm ${qemu_option}


