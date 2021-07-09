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

workspace_dir=${shell_folder}/../
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


    # install package
    echo "install package ..."
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

    if [[ ! -d gcc-arm-none-eabi-10-2020-q4-major ]]; then
        wget --directory-prefix="${toolchains_dir}" https://developer.arm.com/-/media/Files/downloads/gnu-rm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2
        tar -xvf gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2
    fi

    if [[ ! -d gcc-arm-none-eabi-9-2019-q4-major ]]; then
        wget --directory-prefix="${toolchains_dir}" https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2
        tar -xvf gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2
    fi

    #delete tar file
    rm -rf ./*.tar.bz*
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
    git clone https://github.com/FreeRTOS/FreeRTOS.git --recurse-submodules
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

    #build
    cd "${tfm_fwu_dir}"/projects || exit
    ./build.sh

    #run qemu
    #cd ${tfm_fwu_dir}/projects/qemu-tfm
    #./build/qemu-system-arm -machine mps2-an521 -cpu cortex-m33 -kernel ${tfm_fwu_dir}/projects/tfm-fwu/cmake_build/install/outputs/MPS2/AN521/bl2.elf -m 16 -nographic
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
    git clone https://github.com/linaro-swg/optee_examples.git -b 3.12.0

    # Patch for RPMB test, maybe not need
    # Patch from git dir run 'git diff > xxx.diff'
    # patch -d ${nxp865_dir}/optee/optee_examples -p1 < ${shell_folder}/modules/nxp865/patch/optee_examples.diff

    cd "${nxp865_dir}"/build || exit
    ./build.sh nxp_m865_freertos_optee

    # Creat build.sh runqemu.sh rungdb.sh
    cp "${shell_folder}"/modules/nxp865/nxp865_build.sh  "${nxp865_dir}"/build.sh
    cp "${shell_folder}"/modules/nxp865/nxp865_build_ta.sh  "${nxp865_dir}"/build_ta.sh
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

function usage()
{
    echo "build <option>"
    echo "    --a:              Build all"
    echo "    --toolchains:     install toolchains, cmake"
    echo "    --env:            Setup environment, include packages , toolchains cmake"
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
    echo "    --git:            Create git repository 'repository1' "
    echo "    --apache:         Create apache server "
    echo "    -h|--help:        Show this help information"
}

function do_test()
{
    echo "test code"
    #patch -d ${optee_armv8_dir}/build -p1 < ${shell_folder}/modules/opteev8/patch/build.diff
    #sleep 10s
}

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
            do_get_and_build_trusty
            do_get_and_build_nxp865_freertos_optee
            shift;;
        --env)
            do_add_swap
            do_install_package
            do_install_toolchain
            do_install_cmake
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
        --git)
            do_create_git_repository
            shift;;
        --apache)
            do_create_apache_server
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
