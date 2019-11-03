#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
# (c) 2019, Faheem Pervez <trippin1@gmail.com>

set -e
readonly swd="$(pwd)"

readonly magiskboot="$(type -P magiskboot)"
readonly avbtool="../omni/external/avb/avbtool"
readonly mkbootimg="../omni/out/host/linux-x86/bin/mkbootimg"

readonly cmdline='console=null androidboot.hardware=qcom androidboot.memcg=1 lpm_levels.sleep_disabled=1 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 swiotlb=2048 firmware_class.path=/vendor/firmware_mnt/image androidboot.usbcontroller=a600000.dwc3'
readonly input_ramdisk="${swd}/../omni/out/target/product/beyond2qlte/ramdisk-recovery.cpio"
readonly output_compressed_ramdisk="${swd}/out/arch/arm64/boot/ramdisk.cpio.gz"
readonly output_recovery_dtbo="${swd}/out/arch/arm64/boot/recovery_dtbo.img"
readonly output_recovery_image="${swd}/out/arch/arm64/boot/recovery.img"

mapfile -t dtbos < <(find "${swd}/out/arch/arm64/boot/dts/samsung" -name 'sm8150-sec-beyond2qlte-chnhk-overlay*.dtbo')
./tools/mkdtimg create "${output_recovery_dtbo}" --page_size=4096 "${dtbos[@]}"
"$avbtool" add_hash_footer --image "${output_recovery_dtbo}" --partition_size 8388608 --partition_name dtbo
"$magiskboot" compress=gzip "${input_ramdisk}" "${output_compressed_ramdisk}"
"$mkbootimg" --kernel "${swd}/out/arch/arm64/boot/Image-dtb" \
             --ramdisk "${output_compressed_ramdisk}" \
             --recovery_dtbo "${output_recovery_dtbo}" \
             --cmdline "${cmdline}" \
             --base 0x00000000 \
             --kernel_offset 0x00008000 \
             --ramdisk_offset 0x02000000 \
             --second_offset 0x00f00000 \
             --os_version '9.0.0' \
             --os_patch_level '2019-09-01' \
             --tags_offset 0x01e00000 \
             --board 'RILRI20C002' \
             --pagesize 4096 \
             --header_version 1 \
             -o "${output_recovery_image}"

if [ -n "$INSTALL_MAGISK" ] && [ "$INSTALL_MAGISK" -eq "1" ]; then
     # https://github.com/topjohnwu/Magisk/blob/86481c74ffc804d6e3fc01ce89102af3ca4dbab5/scripts/boot_patch.sh - Magisk 20 doesn't work here
     readonly KEEPVERITY=true
     readonly KEEPFORCEENCRYPT=true

     tmpwrkdir="$(mktemp -d)" || exit 1
     trap "rm -rf ${tmpwrkdir}" EXIT
     pushd "${tmpwrkdir}"

     readonly BOOTIMAGE="$(basename "${output_recovery_image}")"
     cp -f "${output_recovery_image}" .
     readonly SHA1=($(sha1sum "${output_recovery_image}"))

     echo "KEEPVERITY=$KEEPVERITY" > config
     echo "KEEPFORCEENCRYPT=$KEEPFORCEENCRYPT" >> config
     [ -n "$SHA1" ] && echo "SHA1=$SHA1" >> config
     echo "RECOVERYMODE=true" >> config

     "$magiskboot" unpack "$BOOTIMAGE"

	fakeroot "$magiskboot" cpio ramdisk.cpio \
"mkdir 000 .backup" \
"mv init .backup/init" \
"add 750 init ${swd}/magiskinit64" \
"patch $KEEPVERITY $KEEPFORCEENCRYPT" \
"add 000 .backup/.magisk config"

     "$magiskboot" repack "${BOOTIMAGE}" "${output_recovery_image}"

     popd
fi
