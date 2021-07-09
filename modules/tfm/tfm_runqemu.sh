#!/bin/bash

# shell folder
shell_folder=$(cd "$(dirname "$0")" || exit;pwd)
workspace_dir=${shell_folder}/../../..

qemu_version=qemu-6.0.0

# toolcqemuhain
qemu_try_dir1=${workspace_dir}/software/qemu
qemu_try_dir2=~/.toolchains/qemu

# get qemu and export
function get_and_export_qemu()
{
    echo "get qemu"
    if [[ -d ${qemu_try_dir1} ]]; then
        if [[ -d ${qemu_try_dir1}/${qemu_version}/build ]]; then
            echo "find qemu from ${qemu_try_dir1}"
            export PATH="${qemu_try_dir1}/${qemu_version}/build:$PATH"
            return
        fi
    fi

    if [[ -d ${qemu_try_dir2} ]]; then
        if [[ -d ${qemu_try_dir2}/${qemu_version}/build ]]; then
            echo "find qemu from ${qemu_try_dir2}"
            export PATH="${qemu_try_dir2}/${qemu_version}/build:$PATH"
            return
        fi
    fi
    
    echo "cann't find qemu, please run root script './build.sh --qemu' ,exit ...."
    exit
}

get_and_export_qemu

qemu_option=
if [[ $1  = "--gdb" ]]; then
    qemu_option+=" -s -S"
    echo "enable gdb, please run script './rungdb', and enter c "
else
    echo "not use gdb, just run"
fi

qemu_option+=" -M mps2-an521 -kernel build/install/outputs/MPS2/AN521/tfm_s.axf"
qemu_option+=" -device loader,file=build/install/outputs/MPS2/AN521/tfm_ns.bin,addr=0x00100000"
qemu_option+=" -serial stdio -display none -m 16"

# run qemu
qemu-system-arm "${qemu_option}"

