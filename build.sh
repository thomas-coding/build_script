#!/bin/bash
shell_folder=$(cd "$(dirname "$0")";pwd)
qemu_dir=/root/software/qemu
toolchains_dir=/root/.toolchains
code_dir=/root/code
freertos_dir=${code_dir}/freertos
optee_armv8_dir=${code_dir}/optee_armv8_3.12.0
optee_armv7_dir=${code_dir}/optee_armv7_3.12.0
tfm_dir=${code_dir}/trusted-firmware-m
tfm_fwu_dir=${code_dir}/tfm-fwu

function do_add_swap()
{
    # Add swap for memory
    echo "Add swap ..."
    dd if=/dev/zero of=/root/swap bs=1024 count=4096000
    chmod 0600 /root/swap
    sudo swapoff -a
    sudo mkswap /root/swap
    sudo swapon /root/swap
    free m
}
export -f do_add_swap

function do_install_package()
{
    # update 
    apt-get update

    # install repo
    mkdir ~/bin
    curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
    chmod a+x ~/bin/repo
    echo "export PATH=~/bin:$PATH" >> ~/.bashrc
    source ~/.bashrc

    # install package
    echo "install package ..."
    apt-get -y install git ninja-build android-tools-adb android-tools-fastboot autoconf \
    automake bc bison build-essential ccache cscope curl device-tree-compiler \
    expect flex ftp-upload gdisk iasl libattr1-dev libcap-dev \
    libfdt-dev libftdi-dev libglib2.0-dev libhidapi-dev libncurses5-dev \
    libpixman-1-dev libssl-dev libtool make \
    mtools netcat python-crypto python3-crypto python-pyelftools \
    python3-pycryptodome python3-pyelftools python-serial python3-serial \
    rsync unzip uuid-dev xdg-utils xterm xz-utils zlib1g-dev python3-pip cmake
    #echo "y" | sudo apt-get install git

    # config git
    git config --global user.email "jinping.wu@verisilicon.com"
    git config --global user.name "Jinping Wu"
}

function do_install_qemu()
{
    # get and install qemu
    echo "install qemu ..."
    if [[ -d ${qemu_dir} ]]; then
        rm -rf ${qemu_dir}
    fi
    mkdir -p ${qemu_dir}
    wget --directory-prefix=${qemu_dir} https://download.qemu.org/qemu-6.0.0.tar.xz
    cd ${qemu_dir}
    tar -xvf qemu-6.0.0.tar.xz
    cd qemu-6.0.0
    ./configure --target-list=aarch64-softmmu,arm-softmmu --enable-debug
    make
}

function do_install_toolchain()
{
    # install toolchain
    echo "install toolchains ..."
    if [[ -d ${toolchains_dir} ]]; then
        rm -rf ${toolchains_dir}
    fi
    mkdir ${toolchains_dir}
    wget --directory-prefix=${toolchains_dir} https://developer.arm.com/-/media/Files/downloads/gnu-rm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2
    wget --directory-prefix=${toolchains_dir} https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2
    cd ${toolchains_dir}
    tar -xvf gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2
    tar -xvf gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2
}

function do_install_cmake()
{
    cd ${toolchains_dir}
    wget  https://github.com/Kitware/CMake/releases/download/v3.20.5/cmake-3.20.5-linux-x86_64.sh
    chmod +x cmake-3.20.5-linux-x86_64.sh
    mkdir cmake-3.20.5-linux-x86_64
    ./cmake-3.20.5-linux-x86_64.sh --skip-license --prefix=./cmake-3.20.5-linux-x86_64
}

function do_get_and_build_freertos()
{
    # freerots
    echo "install freertos ..."
    if [[ -d ${freertos_dir} ]]; then
        rm -rf ${freertos_dir}
    fi

    mkdir -p ${freertos_dir}
    cd ${freertos_dir}
    git clone https://github.com/FreeRTOS/FreeRTOS.git --recurse-submodules
    cd ${freertos_dir}/FreeRTOS

    # creat build.sh runqemu.sh rungdb.sh
    cp ${shell_folder}/freertos/freertos_build.sh  ${freertos_dir}/FreeRTOS/build.sh
    cp ${shell_folder}/freertos/freertos_runqemu.sh  ${freertos_dir}/FreeRTOS/runqemu.sh
    cp ${shell_folder}/freertos/freertos_rungdb.sh  ${freertos_dir}/FreeRTOS/rungdb.sh

    #build
    ./build.sh
}

function do_get_and_build_tfm()
{
    # TFM
    if [[ -d ${tfm_dir} ]]; then
        rm -rf ${tfm_dir}
    fi

    cd ${code_dir}
    git clone --branch TF-Mv1.3.0 https://git.trustedfirmware.org/TF-M/trusted-firmware-m.git
    python3 -m pip install "pip>=21.1.1"
    cd ${tfm_dir}
    python3 -m pip install -r ${tfm_dir}/tools/requirements.txt

    #creat build.sh runqemu.sh rungdb.sh
    cp ${shell_folder}/tfm/tfm_build.sh  ${tfm_dir}/build.sh
    cp ${shell_folder}/tfm/tfm_runqemu.sh  ${tfm_dir}/runqemu.sh
    cp ${shell_folder}/tfm/tfm_rungdb.sh  ${tfm_dir}/rungdb.sh

    #build
    ./build.sh
}

function do_get_and_build_tfm_fwu()
{

    if [[ -d ${tfm_fwu_dir} ]]; then
        rm -rf ${tfm_fwu_dir}
    fi
    
    mkdir -p ${tfm_fwu_dir}/projects

    #download
    cd ${tfm_fwu_dir}/projects
    git clone https://github.com/emb-team/freertos-tfm-fwu.git --recurse-submodules
    git clone https://github.com/emb-team/qemu-tfm
    git clone https://github.com/emb-team/tfm-fwu

    #build qemu
    cd ${tfm_fwu_dir}/projects/qemu-tfm
    mkdir build
    cd ${tfm_fwu_dir}/projects/qemu-tfm/build
    ../configure --target-list=aarch64-softmmu,arm-softmmu
    make

    #build tfm
    cd ${tfm_fwu_dir}/projects/tfm-fwu
    cmake -S . -B cmake_build -DTFM_PLATFORM=mps2/an521 -DTFM_TOOLCHAIN_FILE=toolchain_GNUARM.cmake
    cmake --build cmake_build -- install

    #build freerots
    cd ${tfm_fwu_dir}/projects/freertos-tfm-fwu/freertos_kernel/portable/ThirdParty/GCC/ARM_CM33_TFM
    make

    #build flash
    cd ${tfm_fwu_dir}/projects/tfm-fwu
    ./sign.sh
    gcc -g -o toflash toflash.c
    ./toflash

    #creat build.sh runqemu.sh rungdb.sh
    cp ${shell_folder}/tfm_fwu/tfm_build.sh  ${tfm_fwu_dir}/build.sh
    cp ${shell_folder}/tfm_fwu/tfm_runqemu.sh  ${tfm_fwu_dir}/runqemu.sh
    cp ${shell_folder}/tfm_fwu/tfm_rungdb.sh  ${tfm_fwu_dir}/rungdb.sh

    #run qemu
    #cd ${tfm_fwu_dir}/projects/qemu-tfm
    #./build/qemu-system-arm -machine mps2-an521 -cpu cortex-m33 -kernel ${tfm_fwu_dir}/projects/tfm-fwu/cmake_build/install/outputs/MPS2/AN521/bl2.elf -m 16 -nographic
}

function do_get_and_build_optee_armv8()
{
    if [[ -d ${optee_armv8_dir} ]]; then
        rm -rf ${optee_armv8_dir}
    fi

    mkdir -p ${optee_armv8_dir}
    cd ${optee_armv8_dir}
    echo "y" | repo init -u https://github.com/OP-TEE/manifest.git -m qemu_v8.xml -b 3.12.0

    repo sync
    cd ${optee_armv8_dir}/build

    make toolchains
    make

    #creat build.sh runqemu.sh rungdb.sh
    cp ${shell_folder}/optee/optee_build.sh  ${optee_armv8_dir}/build.sh
    cp ${shell_folder}/optee/optee_runqemu.sh  ${optee_armv8_dir}/runqemu.sh
    cp ${shell_folder}/optee/optee_rungdb.sh  ${optee_armv8_dir}/rungdb.sh
}

function do_get_and_build_optee_armv7()
{
    if [[ -d ${optee_armv7_dir} ]]; then
        rm -rf ${optee_armv7_dir}
    fi

    mkdir -p ${optee_armv7_dir}
    cd ${optee_armv7_dir}
    repo init -u https://github.com/OP-TEE/manifest.git -m default.xml -b 3.12.0
    cd ${optee_armv7_dir}/build
    repo sync
    make toolchains
    make

    #creat build.sh runqemu.sh rungdb.sh
    cp ${shell_folder}/optee/optee_build.sh  ${optee_armv7_dir}/build.sh
    cp ${shell_folder}/optee/optee_runqemu.sh  ${optee_armv7_dir}/runqemu.sh
    cp ${shell_folder}/optee/optee_rungdb.sh  ${optee_armv7_dir}/rungdb.sh
}

function usage()
{
    echo "build <option>"
    echo "    --a:              Build all"
    echo "    --env:            Setup environment, include packages , toolchains cmake"
    echo "    --qemu:           Build qemu"
    echo "    --tfm:            Build tfm"
    echo "    --tfm_fwu:        Build tfm_fwu"
    echo "    --opteev8:        Build optee base on armv8"
    echo "    --opteev7:        Build optee base on armv7"
    echo "    --freertos:       Build freertos"
    echo "    -h|--help:        Show this help information"
}

#parse option
for arg in "$@"; do
    case $arg in
        --a)
            do_add_swap
            do_install_package
            do_install_qemu
            do_install_toolchain
            do_install_cmake
            do_get_and_build_freertos
            do_get_and_build_tfm
            do_get_and_build_tfm_fwu
            do_get_and_build_optee_armv8
            do_get_and_build_optee_armv7
            shift;;
        --env)
            do_add_swap
            do_install_package
            do_install_toolchain
            do_install_cmake
            shift;;
        --qemu)
            do_install_qemu
            shift;;
        --tfm)
            do_get_and_build_tfm
            shift;;
        --tfm_fwu)
            do_get_and_build_tfm_fwu
            shift;;
        --opteev8)
            do_get_and_build_optee_armv8
            shift;;
        --opteev7)
            do_get_and_build_optee_armv7
            shift;;
        --freertos)
            do_get_and_build_freertos
            shift;;
        -h|--help)
            usage
            exit 0
            shift;;
        *)
            ;;
    esac
done