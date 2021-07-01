#!/bin/bash

code_dir=/root/code
tfm_home=${code_dir}/trusted-firmware-m
cmake_bin_dir=~/.toolchains/cmake-3.20.5-linux-x86_64/bin

tfm_mode=ipc
tfm_debug=y
tfm_test=y

export PATH=${cmake_bin_dir}:$PATH
export PATH="/root/.toolchains/gcc-arm-none-eabi-9-2019-q4-major/bin:$PATH"

############## get external lib ##############
if [[ ! -d ${tfm_home}/external ]]; then
    echo "get external lib"
    mkdir ${tfm_home}/external


    #mbedcrypto
    cd ${tfm_home}/external
    git clone --no-checkout --depth 1 --no-single-branch --progress --config "advice.detachedHead=false" "https://github.com/ARMmbed/mbedtls.git" "mbedcrypto-src"
    cd ${tfm_home}/external/mbedcrypto-src/
    git checkout mbedtls-2.25.0


    #tfm test
    cd ${tfm_home}/external
    git clone --no-checkout --progress --config "advice.detachedHead=false" "https://git.trustedfirmware.org/TF-M/tf-m-tests.git" "tfm_test_repo-src"
    cd ${tfm_home}/external/tfm_test_repo-src/
    git checkout TF-Mv1.3.0-RC2


    #mcu boot
    cd ${tfm_home}/external
    git clone --no-checkout --progress --config "advice.detachedHead=false" "https://github.com/mcu-tools/mcuboot.git" "mcuboot-src"
    cd ${tfm_home}/external/mcuboot-src/
    git checkout v1.7.2

fi
############## get external lib ##############


#build_option
build_option=
build_option+=" .. -DTFM_PLATFORM=mps2/an521 -DBL2=False"
build_option+=" -DTFM_TOOLCHAIN_FILE=${tfm_home}/toolchain_GNUARM.cmake"
build_option+=" -DMBEDCRYPTO_PATH=${tfm_home}/external/mbedcrypto-src"
build_option+=" -DTFM_TEST_REPO_PATH=${tfm_home}/external/tfm_test_repo-src"
build_option+=" -DMCUBOOT_PATH=${tfm_home}/external/mcuboot-src"


if [[ "${tfm_mode}" = "ipc" ]]; then
    echo "tfm IPC mode"
    build_option+=" -DTFM_PROFILE=profile_medium"
    build_option+=" -DTFM_PSA_API=ON"
fi

if [[ "${tfm_debug}" = "y" ]]; then
    echo "tfm enable debug"
    build_option+=" -DCMAKE_BUILD_TYPE=Debug"
fi


if [[ "${tfm_test}" = "y" ]]; then
    echo "tfm enable test"
    build_option+=" -DTEST_NS=ON"
    build_option+=" -DTEST_S=ON"
fi

#clean and rebuild
rm -rf ${tfm_home}/build
mkdir ${tfm_home}/build

cd ${tfm_home}/build

cmake ${build_option}
make install

arm-none-eabi-objdump -Slg bin/tfm_s.elf > bin/tfm_s.objdump

