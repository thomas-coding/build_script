#!/bin/bash
shell_folder=$(cd "$(dirname "$0")" || exit;pwd)

# Use shell check
# Install 'python3 –m pip install shellcheck-py' or install vscode shellcheck extension

# Coding style
# https://github.com/google/styleguide/blob/gh-pages/shellguide.md

# For aliyun, user is root, otherwise, maybe it is owner's compile server
# Aliyun, default it is empty, create file in system
# Compile server, build it in current folder

if [[ $(whoami) = "root" ]]; then
    is_root=y
else
    is_root=n
fi

workspace_dir=${shell_folder}/..
code_dir=${workspace_dir}/code
toolchains_dir=${workspace_dir}/.toolchains
software_dir=${workspace_dir}/software

qemu_dir=${software_dir}/qemu

freertos_dir=${code_dir}/freertos
optee_armv8_dir=${code_dir}/optee_armv8_3.12.0
optee_armv7_dir=${code_dir}/optee_armv7_3.12.0
tfm_dir=${code_dir}/trusted-firmware-m
tfm_fwu_dir=${code_dir}/tfm-fwu
trusty_dir=${code_dir}/trusty
nxp865_dir=${code_dir}/nxp865
falcon_qemu_coreboot_dir=${code_dir}/falcon_qemu_coreboot
falcon_qemu_uboot_dir=${code_dir}/falcon_qemu_uboot
alius_dir=${code_dir}/alius
alius_qemu_dir=${code_dir}/alius_qemu
alius_csd_dir=${code_dir}/alius_csd

os_version=unknow
function check_os_version()
{
    echo "check_os_version"
    if grep -Eqi "Ubuntu 20." /etc/issue; then
        echo "os ubuntu 20"
        os_version=ubuntu20
    elif grep -Eqi "Ubuntu 18." /etc/issue; then
        echo "os ubuntu 18"
        os_version=ubuntu18
    elif grep -Eqi "Ubuntu 22." /etc/issue; then
        echo "os ubuntu 22"
        os_version=ubuntu22
    fi
}

function do_add_swap()
{
    # Add swap for memory for aliyun, because of aliyun server is low memory(1G)
    if [[ "${is_root}" = "y" ]]; then
        echo "Add swap ..."
        dd if=/dev/zero of=/root/swap bs=1024 count=4096000
        chmod 0600 /root/swap
        sudo swapoff -a
        sudo mkswap /root/swap
        sudo swapon /root/swap
        free m
    fi
}
export -f do_add_swap

function do_install_package()
{
    # update 
    sudo apt-get update

    # install repo
    if [[ ! -e ~/bin/repo ]]; then
        if [[ ! -d ~/bin ]]; then
            mkdir ~/bin
        fi
        curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
        chmod a+x ~/bin/repo
        echo "export PATH=~/bin:$PATH" >> ~/.bashrc
        # shellcheck source=/dev/null
        source ~/.bashrc
    fi

    if [[ "${os_version}" = "ubuntu20" ]]; then
        # install package
        echo "ubuntu20 install package ..."
        sudo apt-get -y install git ninja-build android-tools-adb android-tools-fastboot autoconf \
        automake bc bison build-essential ccache cscope curl device-tree-compiler \
        expect flex ftp-upload gdisk libattr1-dev libcap-dev \
        libfdt-dev libftdi-dev libglib2.0-dev libhidapi-dev libncurses5-dev \
        libpixman-1-dev libssl-dev libtool make \
        mtools netcat python3-crypto \
        python3-pycryptodome python3-pyelftools  python3-serial \
        rsync unzip uuid-dev xdg-utils xterm xz-utils zlib1g-dev python3-pip cmake \
        libpixman-1-dev libstdc++-8-dev pkg-config libglib2.0-dev libusb-1.0-0-dev \
        libssl-dev bison gcc-multilib zip openssh-server openssh-client apache2
        #echo "y" | sudo apt-get install git
    elif [[ "${os_version}" = "ubuntu18" ]]; then
        # install package
        echo "ubuntu18 install package ..."
        sudo apt-get -y install git ninja-build android-tools-adb android-tools-fastboot autoconf \
        automake bc bison build-essential ccache cscope curl device-tree-compiler \
        expect flex ftp-upload gdisk iasl libattr1-dev libcap-dev \
        libfdt-dev libftdi-dev libglib2.0-dev libhidapi-dev libncurses5-dev \
        libpixman-1-dev libssl-dev libtool make \
        mtools netcat python-crypto python3-crypto python-pyelftools \
        python3-pycryptodome python3-pyelftools python-serial python3-serial \
        rsync unzip uuid-dev xdg-utils xterm xz-utils zlib1g-dev python3-pip cmake \
        libpixman-1-dev libstdc++-8-dev pkg-config libglib2.0-dev libusb-1.0-0-dev \
        libssl-dev bison gcc-multilib zip openssh-server openssh-client apache2
        #echo "y" | sudo apt-get install git
    elif [[ "${os_version}" = "ubuntu22" ]]; then
        # install package
        echo "ubuntu22 install package ..."
        # For repo init
        sudo apt-get -y install python-is-python3
        # For qemu
        sudo apt-get -y install ninja-build pkgconf libglib2.0-dev libpixman-1-dev
        # For linux kernel
        sudo apt-get -y install flex bison
        # For optee
        sudo apt-get -y install python3-pyelftools
        # For uboot
        sudo apt-get -y install libssl-dev
        # For buildroot
        sudo apt-get -y install unzip
        # For gdb
        sudo apt-get -y install libncursesw5 libpython2.7
    fi

    # config git
    git config --global user.email "jinping.wu@verisilicon.com"
    git config --global user.name "Jinping Wu"
}

function do_install_qemu()
{
    # get and install qemu
    echo "install qemu ..."
    if [[ -d ${qemu_dir} ]]; then
        return
    fi
    mkdir -p "${qemu_dir}"
    wget --directory-prefix="${qemu_dir}" https://download.qemu.org/qemu-6.0.0.tar.xz
    cd "${qemu_dir}" || exit
    tar -xvf qemu-6.0.0.tar.xz
    cd qemu-6.0.0 || exit
    ./configure --target-list=aarch64-softmmu,arm-softmmu --enable-debug
    make -j "$(nproc)"
    rm -rf "${qemu_dir}"/qemu-6.0.0.tar.xz
}

function do_install_toolchain()
{
    # install toolchain
    echo "install toolchains ..."

    if [[ ! -d ${toolchains_dir} ]]; then
        mkdir "${toolchains_dir}"
    fi

    cd "${toolchains_dir}" || exit

    if [[ ! -d gcc-arm-none-eabi-10.3-2021.10 ]]; then
        wget --directory-prefix="${toolchains_dir}" https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2
        tar -xvf gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2
    fi

    if [[ ! -d gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf ]]; then
        wget --directory-prefix="${toolchains_dir}" https://developer.arm.com/-/media/Files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf.tar.xz
        tar -xvf gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf.tar.xz
    fi

    if [[ ! -d gcc-arm-10.3-2021.07-x86_64-arm-none-eabi ]]; then
        wget --directory-prefix="${toolchains_dir}" https://developer.arm.com/-/media/Files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-arm-none-eabi.tar.xz
        tar -xvf gcc-arm-10.3-2021.07-x86_64-arm-none-eabi.tar.xz
    fi

    if [[ ! -d gcc-arm-10.3-2021.07-x86_64-aarch64-none-elf ]]; then
        wget --directory-prefix="${toolchains_dir}" https://developer.arm.com/-/media/Files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-aarch64-none-elf.tar.xz
        tar -xvf gcc-arm-10.3-2021.07-x86_64-aarch64-none-elf.tar.xz
    fi
    #delete tar file
    rm -rf ./*.tar.bz* ./*.tar.xz*
}

function do_install_cmake()
{
    cd "${toolchains_dir}" || exit
    if [[ ! -d cmake-3.20.5-linux-x86_64 ]]; then
        wget  https://github.com/Kitware/CMake/releases/download/v3.20.5/cmake-3.20.5-linux-x86_64.sh
        chmod +x cmake-3.20.5-linux-x86_64.sh
        mkdir cmake-3.20.5-linux-x86_64
        ./cmake-3.20.5-linux-x86_64.sh --skip-license --prefix=./cmake-3.20.5-linux-x86_64
        rm -rf cmake-3.20.5-linux-x86_64.sh
    fi
}

function do_get_and_build_freertos()
{
    # freerots
    echo "install freertos ..."
    if [[ -d ${freertos_dir} ]]; then
        echo "freertos already exist ..."
        return
    fi

    mkdir -p "${freertos_dir}"
    cd "${freertos_dir}" || exit
    git clone https://github.com/FreeRTOS/FreeRTOS.git --recurse-submodules -b 202104.00
    cd "${freertos_dir}"/FreeRTOS || exit

    # creat build.sh runqemu.sh rungdb.sh
    cp "${shell_folder}"/modules/freertos/freertos_build.sh  "${freertos_dir}"/FreeRTOS/build.sh
    cp "${shell_folder}"/modules/freertos/freertos_runqemu.sh  "${freertos_dir}"/FreeRTOS/runqemu.sh
    cp "${shell_folder}"/modules/freertos/freertos_rungdb.sh  "${freertos_dir}"/FreeRTOS/rungdb.sh

    #build
    ./build.sh
}

function do_get_and_build_tfm()
{
    # TFM
    if [[ -d ${tfm_dir} ]]; then
        echo "tfm already exist ..."
        return
    fi

    if [[ ! -d ${code_dir} ]]; then
        mkdir -p "${code_dir}"
    fi

    cd "${code_dir}" || exit
    export GIT_SSL_NO_VERIFY=1
    git clone --branch TF-Mv1.3.0 https://git.trustedfirmware.org/TF-M/trusted-firmware-m.git
    python3 -m pip install "pip>=21.1.1"
    cd "${tfm_dir}" || exit
    python3 -m pip install -r "${tfm_dir}"/tools/requirements.txt

    #creat build.sh runqemu.sh rungdb.sh
    cp "${shell_folder}"/modules/tfm/tfm_build.sh  "${tfm_dir}"/build.sh
    cp "${shell_folder}"/modules/tfm/tfm_runqemu.sh  "${tfm_dir}"/runqemu.sh
    cp "${shell_folder}"/modules/tfm/tfm_rungdb.sh  "${tfm_dir}"/rungdb.sh

    #build
    ./build.sh
}

function do_get_and_build_tfm_fwu()
{

    if [[ -d ${tfm_fwu_dir} ]]; then
        echo "tfm fwu already exist ..."
        return
    fi
    
    mkdir -p "${tfm_fwu_dir}"/projects

    #download
    cd "${tfm_fwu_dir}"/projects || exit
    git clone https://github.com/emb-team/freertos-tfm-fwu.git --recurse-submodules
    git clone https://github.com/emb-team/qemu-tfm
    git clone https://github.com/emb-team/tfm-fwu

    #build qemu
    cd "${tfm_fwu_dir}"/projects/qemu-tfm || exit
    mkdir build
    cd "${tfm_fwu_dir}"/projects/qemu-tfm/build || exit
    ../configure --target-list=aarch64-softmmu,arm-softmmu
    make -j "$(nproc)"

    #creat build.sh runqemu.sh rungdb.sh
    cp "${shell_folder}"/modules/tfm_fwu/tfm_fwu_build.sh  "${tfm_fwu_dir}"/projects/build.sh
    cp "${shell_folder}"/modules/tfm_fwu/tfm_fwu_runqemu.sh  "${tfm_fwu_dir}"/projects/runqemu.sh
    cp "${shell_folder}"/modules/tfm_fwu/tfm_fwu_rungdb.sh  "${tfm_fwu_dir}"/projects/rungdb.sh


    patch -d "${tfm_fwu_dir}"/projects/freertos-tfm-fwu/freertos_kernel -p1 < "${shell_folder}"/modules/tfm_fwu/patch/freertos_kernel.diff
    patch -d "${tfm_fwu_dir}"/projects/tfm-fwu -p1 < "${shell_folder}"/modules/tfm_fwu/patch/tfm-fwu.diff

    #build
    cd "${tfm_fwu_dir}"/projects || exit
    ./build.sh

}

# Make toolchains maybe fail, try to check toolchains folder aarch32 and aarch64 bin
# If not exist, treate it as download fail, re-download it
function optee_get_toolchain()
{
    echo "Optee download toolchain "
    for (( c=1; c<=10; c++ ))
    do
        echo "Try $c times"
        make toolchains
        if [ -d ../toolchains/aarch32/bin ] && [ -d ../toolchains/aarch64/bin ]; then
            echo "download toolchains Done"
            break
        fi
        rm -rf ../toolchains
    done
}

function do_get_and_build_optee_armv8()
{
    if [[ -d ${optee_armv8_dir} ]]; then
        echo "optee armv8 already exist ..."
        return
    fi

    mkdir -p "${optee_armv8_dir}"
    cd "${optee_armv8_dir}" || exit
    echo "y" | repo init -u https://github.com/OP-TEE/manifest.git -m qemu_v8.xml -b 3.12.0

    repo sync

    # Patch
    # Patch from git dir run 'git diff > xxx.diff'
    patch -d "${optee_armv8_dir}"/build -p1 < "${shell_folder}"/modules/opteev8/patch/build.diff
    patch -d "${optee_armv8_dir}"/optee_client -p1 < "${shell_folder}"/modules/opteev8/patch/optee_client.diff
    patch -d "${optee_armv8_dir}"/optee_os -p1 < "${shell_folder}"/modules/opteev8/patch/optee_os.diff
    patch -d "${optee_armv8_dir}"/trusted-firmware-a -p1 < "${shell_folder}"/modules/opteev8/patch/trusted-firmware-a.diff

    cd "${optee_armv8_dir}"/build || exit

    optee_get_toolchain
    #make toolchains
    make -j "$(nproc)"

    # Creat build.sh runqemu.sh rungdb.sh
    cp "${shell_folder}"/modules/opteev8/optee_build.sh  "${optee_armv8_dir}"/build.sh
    cp "${shell_folder}"/modules/opteev8/optee_runqemu.sh  "${optee_armv8_dir}"/runqemu.sh
    cp "${shell_folder}"/modules/opteev8/optee_rungdb.sh  "${optee_armv8_dir}"/rungdb.sh
}

function do_get_and_build_optee_armv7()
{
    if [[ -d ${optee_armv7_dir} ]]; then
        echo "optee armv7 already exist ..."
        return
    fi

    mkdir -p "${optee_armv7_dir}"
    cd "${optee_armv7_dir}" || exit || exit
    echo "y" | repo init -u https://github.com/OP-TEE/manifest.git -m default.xml -b 3.12.0
    repo sync

    # Patch
    # Patch from git dir run 'git diff > xxx.diff'
    patch -d "${optee_armv7_dir}"/build -p1 < "${shell_folder}"/modules/opteev7/patch/optee_build.diff
    patch -d "${optee_armv7_dir}"/optee_client -p1 < "${shell_folder}"/modules/opteev7/patch/optee_client.diff
    patch -d "${optee_armv7_dir}"/optee_os -p1 < "${shell_folder}"/modules/opteev7/patch/optee_os.diff
    patch -d "${optee_armv7_dir}"/trusted-firmware-a -p1 < "${shell_folder}"/modules/opteev7/patch/trusted-firmware-a.diff

    cd "${optee_armv7_dir}"/build || exit
    optee_get_toolchain
    #make toolchains
    make -j "$(nproc)"

    #creat build.sh runqemu.sh rungdb.sh
    cp "${shell_folder}"/modules/opteev7/optee_build.sh  "${optee_armv7_dir}"/build.sh
    cp "${shell_folder}"/modules/opteev7/optee_runqemu.sh  "${optee_armv7_dir}"/runqemu.sh
    cp "${shell_folder}"/modules/opteev7/optee_rungdb.sh  "${optee_armv7_dir}"/rungdb.sh
}

function do_get_and_build_trusty()
{
    if [[ -d ${trusty_dir} ]]; then
        echo "trusty already exist ..."
        return
    fi

    # Change python 2.7 for build Trusty os
    sudo update-alternatives --remove-all python
    sudo update-alternatives --install /usr/bin/python python /usr/bin/python2.7 9

    mkdir -p "${trusty_dir}"
    cd "${trusty_dir}" || exit
    echo "y" | repo init -u https://android.googlesource.com/trusty/manifest -b master
    # Change old manifest for compile ok
    # cp ${shell_folder}/modules/trusty/manifest_0704.xml  ${trusty_dir}/.repo/manifests/
    # repo init -m manifest_0704.xml

    # Change ~/.gitconfig, add below for get trusty from verisilicon mirror
    # [url "http://mirror-spsd.verisilicon.com:8080/aosp"]
    #    insteadOf = https://android.googlesource.com

    repo sync -v -c -j4 --no-clone-bundle

    # Build
    # ./trusty/vendor/google/aosp/scripts/build.py --skip-tests --jobs 1  qemu-generic-arm64-gicv3-test-debug
    ./trusty/vendor/google/aosp/scripts/build.py --skip-tests qemu-generic-arm64-gicv3-test-debug

    # Creat build.sh runqemu.sh rungdb.sh
    cp "${shell_folder}"/modules/trusty/trusty_build.sh  "${trusty_dir}"/build.sh
    cp "${shell_folder}"/modules/trusty/trusty_runqemu.sh  "${trusty_dir}"/runqemu.sh
    cp "${shell_folder}"/modules/trusty/trusty_rungdb.sh  "${trusty_dir}"/rungdb.sh

    # After trusty build, change back to python3.6
    sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.6 10
}

function do_get_and_build_nxp865_freertos_optee()
{
    if [[ -d ${nxp865_dir} ]]; then
        echo "nxp already exist ..."
        return
    fi

    mkdir -p "${nxp865_dir}"
    cd "${nxp865_dir}" || exit
    repo init -u ssh://gerrit-spsd.verisilicon.com:29418/manifest \
    --repo-url=ssh://gerrit-spsd.verisilicon.com:29418/git-repo \
    -b spsd/master -m NXP/M865_freertos.xml

    repo sync

    # Add examples
    cd "${nxp865_dir}"/optee || exit
    # optee_os base on 3.10.0, so other parts also use 3.10.0
    git clone https://github.com/linaro-swg/optee_examples.git -b 3.10.0

    git clone https://github.com/OP-TEE/optee_test.git -b 3.10.0
    git clone https://github.com/OP-TEE/optee_client.git -b 3.10.0

    # Patch for RPMB test, maybe not need
    # Patch from git dir run 'git diff > xxx.diff'
    # patch -d ${nxp865_dir}/optee/optee_examples -p1 < ${shell_folder}/modules/nxp865/patch/optee_examples.diff

    cd "${nxp865_dir}"/build || exit
    ./build.sh nxp_m865_freertos_optee

    # Creat build.sh runqemu.sh rungdb.sh
    cp "${shell_folder}"/modules/nxp865/nxp865_build.sh  "${nxp865_dir}"/build.sh
    cp "${shell_folder}"/modules/nxp865/nxp865_build_ta.sh  "${nxp865_dir}"/build_ta.sh
    cp "${shell_folder}"/modules/nxp865/toflash.c  "${nxp865_dir}"/toflash.c
}

function do_get_and_build_falcon_qemu_coreboot()
{
    if [[ -d ${falcon_qemu_coreboot_dir} ]]; then
        echo "falcon qemu coreboot already exist ..."
        return
    fi

    mkdir -p "${falcon_qemu_coreboot_dir}"
    cd "${falcon_qemu_coreboot_dir}" || exit
    repo init -u ssh://gerrit-spsd.verisilicon.com:29418/manifest \
    --repo-url=ssh://gerrit-spsd.verisilicon.com:29418/git-repo \
    -b spsd/master -m Falcon/QEMU_coreboot.xml

    repo sync -j4 --no-clone-bundle

    # Change to old data version which compile and run ok
    repo forall -c 'commitID=`git log --before "2021-03-09 07:00" -1 --pretty=format:"%H"`; git reset --hard $commitID'

    # Build
    cd "${falcon_qemu_coreboot_dir}"/build || exit
    ./build.sh qemu

    # Creat build.sh runqemu.sh rungdb.sh
    cp "${shell_folder}"/modules/falcon_qemu/falcon_qemu_build.sh  "${falcon_qemu_coreboot_dir}"/build.sh
    cp "${shell_folder}"/modules/falcon_qemu/falcon_qemu_runqemu.sh  "${falcon_qemu_coreboot_dir}"/runqemu.sh
    cp "${shell_folder}"/modules/falcon_qemu/falcon_qemu_rungdb.sh  "${falcon_qemu_coreboot_dir}"/rungdb.sh
}

function do_get_and_build_falcon_qemu_uboot()
{
    if [[ -d ${falcon_qemu_uboot_dir} ]]; then
        echo "falcon qemu coreboot already exist ..."
        return
    fi

    mkdir -p "${falcon_qemu_uboot_dir}"
    cd "${falcon_qemu_uboot_dir}" || exit
    repo init -u ssh://gerrit-spsd.verisilicon.com:29418/manifest \
    --repo-url=ssh://gerrit-spsd.verisilicon.com:29418/git-repo \
    -b spsd/master -m Falcon/QEMU.xml

    repo sync -j4 --no-clone-bundle

    # Change to old data version which compile and run ok
    repo forall -c 'commitID=`git log --before "2021-03-09 07:00" -1 --pretty=format:"%H"`; git reset --hard $commitID'

    # Build
    cd "${falcon_qemu_uboot_dir}"/build || exit
    ./build.sh qemu

    # Creat build.sh runqemu.sh rungdb.sh
    cp "${shell_folder}"/modules/falcon_qemu/falcon_qemu_build.sh  "${falcon_qemu_uboot_dir}"/build.sh
    cp "${shell_folder}"/modules/falcon_qemu/falcon_qemu_runqemu.sh  "${falcon_qemu_uboot_dir}"/runqemu.sh
    cp "${shell_folder}"/modules/falcon_qemu/falcon_qemu_rungdb.sh  "${falcon_qemu_uboot_dir}"/rungdb.sh
}



function do_get_and_build_alius()
{
    if [[ -d ${alius_dir} ]]; then
        echo "alius already exist ..."
        return
    fi

    mkdir -p "${alius_dir}"
    cd "${alius_dir}" || exit
    repo init -u ssh://gerrit-spsd.verisilicon.com:29418/manifest --repo-url=ssh://gerrit-spsd.verisilicon.com:29418/git-repo -b spsd/master -m Alius/linuxsdk.xml

    repo sync -j4 -c

    # Build
    cd "${alius_dir}"/build || exit
    ./build.sh alius

    # Creat build.sh
    cp "${shell_folder}"/modules/alius/alius_build.sh  "${alius_dir}"/build.sh
    cp "${shell_folder}"/modules/alius/alius_build_m33.sh  "${alius_dir}"/build_m33.sh
    cp "${shell_folder}"/modules/alius/alius_runqemu_m33.sh  "${alius_dir}"/runqemu_m33.sh
    cp "${shell_folder}"/modules/alius/alius_rungdb_m33.sh  "${alius_dir}"/rungdb_m33.sh

}

function do_get_alius_csd()
{
    if [[ -d ${alius_csd_dir} ]]; then
        echo "alius csd mirror already exist ..."
        return
    fi

    mkdir -p "${alius_csd_dir}"
    cd "${alius_csd_dir}" || exit

    git clone "ssh://cn1396@gerrit-spsd.verisilicon.com:29418/gitlab/alius/u-boot"
    git clone "ssh://cn1396@gerrit-spsd.verisilicon.com:29418/gitlab/alius/trusted-firmware-m"
    git clone "ssh://cn1396@gerrit-spsd.verisilicon.com:29418/gitlab/alius/trusted-firmware-a"
    git clone "ssh://cn1396@gerrit-spsd.verisilicon.com:29418/gitlab/alius/linux"
    git clone "ssh://cn1396@gerrit-spsd.verisilicon.com:29418/gitlab/alius/ipd-release"
    git clone "ssh://cn1396@gerrit-spsd.verisilicon.com:29418/gitlab/alius/freertos" --recurse-submodules
    git clone "ssh://cn1396@gerrit-spsd.verisilicon.com:29418/gitlab/alius/baremetal-m33"
    git clone "ssh://cn1396@gerrit-spsd.verisilicon.com:29418/gitlab/alius/baremetal-m0plus"
    git clone "ssh://cn1396@gerrit-spsd.verisilicon.com:29418/gitlab/alius/baremetal-a32"
    #git clone "ssh://cn1396@gerrit-spsd.verisilicon.com:29418/github/qemu/qemu"
    git clone https://gitlab.com/qemu-project/qemu.git

    cd "${alius_csd_dir}/baremetal-a32" || exit
    #git log --until=2021-08-18
    git checkout 5752930b0a73198ca491154aaf703a2f20d65041

    cd "${alius_csd_dir}/u-boot" || exit
    git checkout origin/alius-fpga

    cd "${alius_csd_dir}/trusted-firmware-m" || exit
    git checkout  origin/alius-fpga

    cd "${alius_csd_dir}/trusted-firmware-a" || exit
    git checkout  origin/alius-fpga

    cd "${alius_csd_dir}/linux" || exit
    git checkout  origin/alius-fpga

    cd "${alius_csd_dir}/freertos" || exit
    git checkout  origin/alius-fpag-vsi-m33

    # Get qemu v5.2.0, patch alius machine, build 
    cd "${alius_csd_dir}/qemu" || exit
    git checkout -b my5.2.2 v5.2.0
    git submodule init
    git submodule update --recursive
    
    # Patch
    patch -d "${alius_csd_dir}"/qemu -p1 < "${shell_folder}"/modules/alius_csd/patch/alius_csd_qemu.diff
    patch -d "${alius_csd_dir}"/freertos -p1 < "${shell_folder}"/modules/alius_csd/patch/alius_csd_freertos.diff
    patch -d "${alius_csd_dir}"/baremetal-m33 -p1 < "${shell_folder}"/modules/alius_csd/patch/alius_csd_baremetal-m33.diff

    # Build qemu
    #git fetch "ssh://cn1396@gerrit-spsd.verisilicon.com:29418/github/qemu/qemu" refs/changes/48/7848/3 && git cherry-pick FETCH_HEAD
    ./configure --target-list=arm-softmmu --enable-debug
    make -j "$(nproc)"

    # Create build.sh runqemu.sh rungdb.sh
    cp "${shell_folder}"/modules/alius_csd/alius_csd_build.sh  "${alius_csd_dir}"/build.sh
    cp "${shell_folder}"/modules/alius_csd/alius_csd_runqemu.sh  "${alius_csd_dir}"/runqemu.sh
    cp "${shell_folder}"/modules/alius_csd/alius_csd_rungdb.sh  "${alius_csd_dir}"/rungdb.sh

    # Create M33 TFM and Freertos build.sh runqemu.sh rungdb.sh
    cp "${shell_folder}"/modules/alius_csd/alius_csd_build_m33.sh  "${alius_csd_dir}"/build_m33.sh
    cp "${shell_folder}"/modules/alius_csd/alius_csd_runqemu_m33.sh  "${alius_csd_dir}"/runqemu_m33.sh
    cp "${shell_folder}"/modules/alius_csd/alius_csd_rungdb_m33.sh  "${alius_csd_dir}"/rungdb_m33.sh

    # Create M33 baremetal build.sh runqemu.sh rungdb.sh
    cp "${shell_folder}"/modules/alius_csd/alius_csd_build_m33_bm.sh  "${alius_csd_dir}"/build_m33_bm.sh
    cp "${shell_folder}"/modules/alius_csd/alius_csd_runqemu_m33_bm.sh  "${alius_csd_dir}"/runqemu_m33_bm.sh
    cp "${shell_folder}"/modules/alius_csd/alius_csd_rungdb_m33_bm.sh  "${alius_csd_dir}"/rungdb_m33_bm.sh


    # Create a32 baremetal build.sh runqemu.sh rungdb.sh
    cp "${shell_folder}"/modules/alius_csd/alius_csd_runqemu_a32_bm.sh  "${alius_csd_dir}"/runqemu_a32_bm.sh
    cp "${shell_folder}"/modules/alius_csd/alius_csd_rungdb_a32_bm.sh  "${alius_csd_dir}"/rungdb_a32_bm.sh
}

function do_get_alius_qemu()
{
    if [[ -d ${alius_qemu_dir} ]]; then
        echo "alius qemu already exist ..."
        return
    fi

    # Downlaod code base
    mkdir -p "${alius_qemu_dir}"
    cd "${alius_qemu_dir}" || exit
    repo init -u ssh://gerrit-spsd.verisilicon.com:29418/manifest --repo-url=ssh://gerrit-spsd.verisilicon.com:29418/git-repo -b spsd/master -m Alius/linuxsdk.xml
    repo sync -j4 -c

    # Install qemu
    cd "${alius_qemu_dir}"|| exit
    git clone "ssh://cn1396@gerrit-spsd.verisilicon.com:29418/gitlab/qemu/qemu"
    cd "${alius_qemu_dir}"/qemu || exit
    git checkout -b my_branch origin/alius
    patch -d "${alius_qemu_dir}"/qemu -p1 < "${shell_folder}"/modules/alius_qemu/patch/alius_qemu_qemu.diff
    ./configure --target-list=arm-softmmu --enable-debug
    make -j8

    # Patch ATF and Build
    patch -d "${alius_qemu_dir}"/build -p1 < "${shell_folder}"/modules/alius_qemu/patch/alius_qemu_build.diff
    patch -d "${alius_qemu_dir}"/atf -p1 < "${shell_folder}"/modules/alius_qemu/patch/alius_qemu_atf.diff

    # Build
    cd "${alius_qemu_dir}"/build || exit
    ./build.sh alius

    # Creat build.sh
    cp "${shell_folder}"/modules/alius_qemu/alius_qemu_build.sh  "${alius_qemu_dir}"/build.sh
    cp "${shell_folder}"/modules/alius_qemu/alius_qemu_build_m33.sh  "${alius_qemu_dir}"/build_m33.sh
    cp "${shell_folder}"/modules/alius_qemu/alius_qemu_runqemu_m33.sh  "${alius_qemu_dir}"/runqemu_m33.sh
    cp "${shell_folder}"/modules/alius_qemu/alius_qemu_rungdb_m33.sh  "${alius_qemu_dir}"/rungdb_m33.sh
    cp "${shell_folder}"/modules/alius_qemu/alius_qemu_runqemu_a32.sh  "${alius_qemu_dir}"/runqemu_a32.sh
    cp "${shell_folder}"/modules/alius_qemu/alius_qemu_rungdb_a32.sh  "${alius_qemu_dir}"/rungdb_a32.sh

}

function do_create_git_repository()
{
    git init --bare /gitshop/repository1.git
    echo "Use 'git clone root@8.210.111.180:/gitshop/repository1.git' to get repository"
    # no password: client pubkey -> server authed pubkey
    # client pubkey: ~/.ssh/id_rsa.pub
    # server pubkey: ~/.ssh/authorized_keys
}



function do_create_apache_server()
{
    sudo apt-get -y install apache2
    if [[ ! -d /var/www/html/share ]]; then
        cd /var/www/html/ || exit
        mkdir -p /var/www/html/share
    fi
    sudo /etc/init.d/apache2 restart
    echo "Use 'http://8.210.111.180/share' (your ip instead of 8.210.111.180) to visit apache server"

    # Clone doc from github
    cd /var/www/html/share || exit
    git clone https://github.com/thomas-coding/doc.git
}


function do_install_vnc_server()
{
    sudo apt-get install -y vnc4server
    echo "please input password, less then 8"
    vncserver
}

function do_install_vpn_server()
{
    cd modules/vpn
    chmod +x pptpd_vpn.sh
    ./pptpd_vpn.sh
}

function usage()
{
    echo "build <option>"
    echo "    --a:              Build all"
    echo "    --toolchains:     install toolchains, cmake"
    echo "    --env:            Setup environment, include packages , toolchains cmake"
    echo "    --package:        Install packages"
    echo "    --qemu:           Build qemu"
    echo "    --tfm:            Build tfm"
    echo "    --tfm_fwu:        Build tfm_fwu"
    echo "    --opteev8:        Build optee base on armv8"
    echo "    --opteev7:        Build optee base on armv7"
    echo "    --freertos:       Build freertos"
    echo "    --trusty:         Build trusty"
    echo "    --nxp865:         Build nxp865 with freertos and optee"
    echo "    --falcon_qc:      Build falcon qemu coreboot"
    echo "    --falcon_qemu:    Build falcon qemu uboot"
    echo "    --alius:          Build alius"
    echo "    --alius_csd:      Get alius csd mirror"
    echo "    --git:            Create git repository 'repository1' "
    echo "    --apache:         Create apache server "
    echo "    --vnc:            Install vnc server, only cmdline mode "
    echo "    -h|--help:        Show this help information"
}

function do_test()
{
    echo "test code"
    #patch -d ${optee_armv8_dir}/build -p1 < ${shell_folder}/modules/opteev8/patch/build.diff
    #sleep 10s
}

# prebuild
check_os_version

# No verify ssl cert
export GIT_SSL_NO_VERIFY=1

#parse option
start_time=${SECONDS}
module=
for arg in "$@"; do
    module+=$arg 
    case $arg in
        --test)
            do_test
            shift;;
        --a)
            #do_add_swap
            do_install_package
            do_install_qemu
            do_install_toolchain
            do_install_cmake
            do_get_and_build_freertos
            do_get_and_build_tfm
            do_get_and_build_tfm_fwu
            do_get_and_build_optee_armv8
            do_get_and_build_optee_armv7
            do_get_and_build_trusty
            do_get_and_build_nxp865_freertos_optee
            shift;;
        --env)
            #do_add_swap
            do_install_package
            do_install_toolchain
            do_install_cmake
            shift;;
        --package)
            do_install_package
            shift;;
        --toolchains)
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
        --trusty)
            do_get_and_build_trusty
            shift;;
        --nxp865)
            do_get_and_build_nxp865_freertos_optee
            shift;;
        --falcon_qc)
            do_get_and_build_falcon_qemu_coreboot
            shift;;
        --falcon_qemu)
            do_get_and_build_falcon_qemu_uboot
            shift;;
        --alius)
            do_get_and_build_alius
            shift;;
        --alius_csd)
            do_get_alius_csd
            shift;;
        --alius_qemu)
            do_get_alius_qemu
            shift;;
        --git)
            do_create_git_repository
            shift;;
        --apache)
            do_create_apache_server
            shift;;
        --vnc)
            do_install_vnc_server
            shift;;
        --vpn)
            do_install_vpn_server
            shift;;
        -h|--help)
            usage
            exit 0
            shift;;
        *)
            ;;
    esac
done

finish_time=${SECONDS}
duration=$((finish_time-start_time))
elapsed_time="$((duration / 60))m $((duration % 60))s"
echo "do ${module} use: ${elapsed_time}"
