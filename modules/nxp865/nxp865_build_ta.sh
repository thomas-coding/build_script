#!/bin/bash

SHELL_FOLDER=$(cd "$(dirname "$0")" || exit;pwd)
OPTEE_DIR=${SHELL_FOLDER}/optee

#toolchian
export PATH="/home/cn1396/.toolchain/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu/bin:$PATH"

#build hello world ta
cd "${OPTEE_DIR}"/optee_examples/hello_world/ta || exit
export TA_DEV_KIT_DIR=${OPTEE_DIR}/optee_os/out/arm-plat-imx/export-ta_arm64
make CROSS_COMPILE=aarch64-none-linux-gnu-

#build secure storage ta
cd "${OPTEE_DIR}"/optee_examples/secure_storage/ta || exit
export TA_DEV_KIT_DIR=${OPTEE_DIR}/optee_os/out/arm-plat-imx/export-ta_arm64
make CROSS_COMPILE=aarch64-none-linux-gnu-