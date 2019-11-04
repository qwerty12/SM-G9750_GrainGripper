#!/bin/bash
set -e

test -d out || mkdir out

TOOLCHAIN_BASE="$(pwd)/../PLATFORM/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9"
CLANG_BASE="$(pwd)/../toolchain/llvm-arm-toolchain-ship/6.0"
if [ -n "$USE_CCACHE" ] && [ "$USE_CCACHE" -eq "1" ]; then
	export PATH="${CLANG_BASE}/bin:${TOOLCHAIN_BASE}/bin:$PATH"
	KERNEL_LLVM_BIN="ccache clang"
else
	KERNEL_LLVM_BIN="${CLANG_BASE}/bin/clang"
fi
BUILD_CROSS_COMPILE="${TOOLCHAIN_BASE}/bin/aarch64-linux-android-"
KERNEL_LLVM_CFP="${CLANG_BASE}-cfp/bin/clang"

CLANG_TRIPLE=aarch64-linux-gnu-
KERNEL_MAKE_ENV=("DTC_EXT=$(pwd)/tools/dtc" "CONFIG_BUILD_ARM64_DT_OVERLAY=y")
PROC="$(($(nproc) + 1))"
test -z "$ANDROID_VERSION" && ANDROID_VERSION='990000' # qwerty12
[ "$USER" = "fp" ] && export LOCALVERSION='-GrainGripper' KBUILD_BUILD_USER='93270' KBUILD_BUILD_HOST='Wintermute'

make -j$PROC -C "$(pwd)" O="$(pwd)/out" "${KERNEL_MAKE_ENV[@]}" ARCH=arm64 CROSS_COMPILE="${BUILD_CROSS_COMPILE}" REAL_CC="${KERNEL_LLVM_BIN}" CFP_CC="$KERNEL_LLVM_CFP" CLANG_TRIPLE=$CLANG_TRIPLE ANDROID_VERSION="$ANDROID_VERSION" LOCALVERSION="$LOCALVERSION" beyond2qlte_chn_hk_q12_defconfig
make -j$PROC -C "$(pwd)" O="$(pwd)/out" "${KERNEL_MAKE_ENV[@]}" ARCH=arm64 CROSS_COMPILE="${BUILD_CROSS_COMPILE}" REAL_CC="${KERNEL_LLVM_BIN}" CFP_CC="$KERNEL_LLVM_CFP" CLANG_TRIPLE=$CLANG_TRIPLE ANDROID_VERSION="$ANDROID_VERSION" LOCALVERSION="$LOCALVERSION"
 
#cp -f out/arch/arm64/boot/Image "$(pwd)/arch/arm64/boot/Image"
"$(pwd)/tools/dtc" "$(pwd)/arch/arm64/boot/dts/qcom/03_dtbdump_<e,u_AAy.dts" >> "$(pwd)/out/arch/arm64/boot/Image-dtb" # TODO: shove this into the relevant Makefile
"$(pwd)/create_image.sh"
