#!/bin/bash

SHELL_FOLDER=$(cd "$(dirname "$0")" || exit;pwd)

# workspace folder
workspace_dir=${SHELL_FOLDER}/../..


# toolchain
toolchains_try_dir1=~/.toolchains;
toolchains_try_dir2=${workspace_dir}/.toolchains;
toolchian=gcc-arm-none-eabi-9-2019-q4-major

# cmake
cmake_try_dir1=${toolchains_try_dir1}/cmake-3.20.5-linux-x86_64
cmake_try_dir2=${toolchains_try_dir2}/cmake-3.20.5-linux-x86_64

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

# get cmake and export
function get_and_export_cmake()
{
    echo "get cmake"
    if [[ -d ${cmake_try_dir1} ]]; then
        if [[ -d ${cmake_try_dir1}/bin ]]; then
            echo "find cmake from ${cmake_try_dir1}"
            export PATH="${cmake_try_dir1}/bin:$PATH"
            return
        fi
    fi
    
    if [[ -d ${cmake_try_dir2} ]]; then
        if [[ -d ${cmake_try_dir2}/bin ]]; then
            echo "find cmake from ${cmake_try_dir2}"
            export PATH="${cmake_try_dir2}/bin:$PATH"
            return
        fi
    fi
    echo "cann't find cmake, please run root script './build.sh --cmake' ,exit ...."
    exit
}

get_and_export_toolchain
get_and_export_cmake


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
