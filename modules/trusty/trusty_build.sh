#!/bin/bash



cd build || exit
#make 
#for optee client
make optee-os buildroot
#arm-tf buildroot edk2 linux optee-os soc-term
#make -j8 linux
#./toolchains/aarch64/bin/aarch64-linux-gnu-objdump -S -l -z linux/vmlinux > linux/vmlinux.txt
#make optee-os
#make arm-tf