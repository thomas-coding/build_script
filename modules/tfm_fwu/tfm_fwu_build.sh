#!/bin/bash

export PATH="/root/.toolchains/gcc-arm-none-eabi-9-2019-q4-major/bin:$PATH"
export PATH="/root/.toolchains/cmake-3.20.5-linux-x86_64/bin:$PATH"

SHELL_FOLDER=$(cd "$(dirname "$0")" || exit;pwd)
#QEMU_DIR=${SHELL_FOLDER}/qemu-tfm
TFM_DIR=${SHELL_FOLDER}/tfm-fwu
FREERTOS_DIR=${SHELL_FOLDER}/freertos-tfm-fwu
CMAKE_BUILD_DIR=${TFM_DIR}/cmake_build

#build tfm
cd ${TFM_DIR} || exit

if [[ ! -d ${CMAKE_BUILD_DIR} ]]; then
    mkdir "${CMAKE_BUILD_DIR}"
fi

cmake -S . -B cmake_build -DTFM_PLATFORM=mps2/an521 -DTFM_TOOLCHAIN_FILE=toolchain_GNUARM.cmake
cmake --build cmake_build -- install

#build freerots
cd "${FREERTOS_DIR}"/freertos_kernel/portable/ThirdParty/GCC/ARM_CM33_TFM || exit
make DEBUG=1

#build flash
cd ${TFM_DIR} || exit
./sign.sh
gcc -g -o toflash toflash.c
./toflash
