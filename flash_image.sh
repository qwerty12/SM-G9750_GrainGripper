#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
# (c) 2019, Faheem Pervez <trippin1@gmail.com>

set -eo pipefail
readonly recovery_image="$(pwd)/out/arch/arm64/boot/recovery.img"
readonly recovery_basename="$(basename "$recovery_image")"

if [ ! -f "$recovery_image" ] || [ -z "$recovery_basename" ]; then
	echo "${recovery_image} not found!"
	exit 1
fi

echo -n "Waiting for SM-G9750 to flash ${recovery_image} onto..."
adb wait-for-any
devices="$(adb devices -l | grep 'model:SM_G9750')"
if [ "$(echo "$devices" | wc -l)" -ne 1 ]; then
	echo ' found more than one, exiting.'
	exit 1
fi

read -r -a devices <<< "$devices"
serial="${devices[0]}"
mode="${devices[1]}"
if [ -z "$serial" ] || [ -z "$mode" ]; then
	echo ' could not determine serial and/or boot mode of connected S10+'
	exit 1
fi

echo " found!"

readonly sync='sync ; echo 3 > /proc/sys/vm/drop_caches ; sync'
if [ "$mode" = "recovery" ]; then
	readonly dest="/tmp"
	adb -s "$serial" push "$recovery_image" "$dest/"
	adb -s "$serial" shell "sh -c 'cat /tmp/${recovery_basename} /dev/zero >/dev/block/by-name/recovery 2>/dev/null && $sync ; reboot recovery'"
elif [ "$mode" = "device" ]; then
	readonly dest="/data/local/tmp"
	adb -s "$serial" push "$recovery_image" "$dest/"
	adb -s "$serial" shell "su -c 'cat ${dest}/${recovery_basename} /dev/zero >/dev/block/by-name/recovery 2>/dev/null && $sync ; rm -f ${dest}/${recovery_basename} ; svc power reboot recovery'"
fi

#Heimdall 1.4.2 doesn't work for the S10+ under Ubuntu, so if you can't even get to TWRP, Odin in Windows is your only option
