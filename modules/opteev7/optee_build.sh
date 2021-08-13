#!/bin/bash

function usage()
{
    echo "usage:'./build.sh <option>' "
    echo "option: "
    echo "    all:              Build all"
    echo "    optee:            Build optee"
    echo "    atf:              Build trusted firmware a"
    echo "    linux:            Build linux"
    echo "    optee_client:     Build optee client"
    echo "    buildroot:        Build buildroot"
    echo "    qemu:             Build qemu"
    echo "    -h|--help:        Show this help information"
}

cd build || exit

#parse option
start_time=${SECONDS}
module=
for arg in "$@"; do
    module+=$arg 
    case $arg in
        all)
            make -j "$(nproc)" arm-tf buildroot edk2 linux optee-os soc-term
            shift;;
        optee)
            make -j "$(nproc)" optee-os
            shift;;
        atf)
            make -j "$(nproc)" arm-tf
            shift;;
        linux)
            make -j "$(nproc)" linux
            shift;;
        optee_client)
            make -j "$(nproc)" optee-os buildroot
            shift;;
        buildroot)
            make -j "$(nproc)" buildroot
            shift;;
        qemu)
            make -j "$(nproc)" qemu
            shift;;
        -h|--help)
            usage
            exit 0
            shift;;           
        *)
            echo "unknow arg $arg, please run './build.sh -h' for more infomation "
            exit 0
            ;;
    esac
done

finish_time=${SECONDS}
duration=$((finish_time-start_time))
elapsed_time="$((duration / 60))m $((duration % 60))s"

if [[ ${module}  = "" ]]; then
    echo "unknow arg $arg, please run './build.sh -h' for more infomation "
else
    echo "build ${module} use: ${elapsed_time}"
fi