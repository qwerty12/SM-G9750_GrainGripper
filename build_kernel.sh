#!/bin/bash

#!/bin/bash

#export ARCH=arm64
#export PATH=$(pwd)/../PLATFORM/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin:$PATH
#export KERNEL_MAKE_ENV="DTC_EXT=$(pwd)/tools/dtc CONFIG_BUILD_ARM64_DT_OVERLAY=y"

mkdir out

BUILD_CROSS_COMPILE=$(pwd)/../PLATFORM/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
KERNEL_LLVM_BIN=$(pwd)/toolchain/llvm-arm-toolchain-ship/6.0/bin/clang
KERNEL_LLVM_CFP=$(pwd)/toolchain/llvm-arm-toolchain-ship/6.0-cfp/bin/clang
#BUILD_CROSS_COMPILE=$BUILD_TOP_DIR/PLATFORM/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
#KERNEL_LLVM_BIN=$BUILD_TOP_DIR/toolchain/llvm-arm-toolchain-ship/6.0/bin/clang
CLANG_TRIPLE=aarch64-linux-gnu-
KERNEL_MAKE_ENV="DTC_EXT=$(pwd)/tools/dtc CONFIG_BUILD_ARM64_DT_OVERLAY=y"
PROC="$(($(nproc) + 1))"
test -z "$ANDROID_VERSION" && ANDROID_VERSION=990000 # qwerty12

make -j$PROC -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CFP_CC=$KERNEL_LLVM_CFP CLANG_TRIPLE=$CLANG_TRIPLE ANDROID_VERSION="$ANDROID_VERSION" beyond2qlte_chn_hk_q12_defconfig
make -j$PROC -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CFP_CC=$KERNEL_LLVM_CFP CLANG_TRIPLE=$CLANG_TRIPLE ANDROID_VERSION="$ANDROID_VERSION"
 
cp out/arch/arm64/boot/Image $(pwd)/arch/arm64/boot/Image
