#!/bin/bash


#build
cd build
export OPTEE_WITH_FREERTOS=1
export FREERTOS_FAT_FS=1
#./build.sh nxp_m865_freertos freertos
./build.sh nxp_m865_freertos freertos

