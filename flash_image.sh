#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
# (c) 2019, Faheem Pervez <trippin1@gmail.com>

set -eo pipefail
readonly model='SM_G9750'
readonly recovery_image="$(pwd)/out/arch/arm64/boot/recovery.img"
readonly recovery_basename="$(basename "$recovery_image")"

if [ ! -f "$recovery_image" ] || [ -z "$recovery_basename" ]; then
	echo "ERROR: ${recovery_image} not found!"
	exit 1
fi

echo -n "Waiting for an ${model} to flash ${recovery_image} onto... "
adb wait-for-any 2>/dev/null
devices="$(adb devices -l | grep "model:${model}")"
if [ "$(echo "$devices" | wc -l)" -ne 1 ]; then
	printf '\nERROR: Found more than one %s, exiting.\n' "${model}"
	exit 1
fi

read -r -a devices <<< "$devices"
serial="${devices[0]}"
mode="${devices[1]}"
if [ -z "$serial" ] || [ -z "$mode" ]; then
	printf '\nERROR: Could not determine serial and/or boot mode of connected %s\n' "${model}"
	exit 1
else
	echo 'found!'
fi

readonly sync='sync ; echo 3 > /proc/sys/vm/drop_caches ; sync'
if [ "$mode" = "recovery" ]; then
	readonly dest="/tmp"
	adb -s "$serial" push "$recovery_image" "$dest/"
	adb -s "$serial" shell "sh -c 'cat /tmp/${recovery_basename} /dev/zero >/dev/block/by-name/recovery 2>/dev/null && $sync ; reboot recovery'"
elif [ "$mode" = "device" ]; then
	readonly dest="/data/local/tmp"
	adb -s "$serial" push "$recovery_image" "$dest/"
	adb -s "$serial" shell "su -c 'cat ${dest}/${recovery_basename} /dev/zero >/dev/block/by-name/recovery 2>/dev/null && $sync ; rm -f ${dest}/${recovery_basename} ; svc power reboot recovery'"
else
	#Heimdall 1.4.2 doesn't work for the S10+ under Ubuntu, so if you can't even get to TWRP, Odin in Windows is your only option
	echo "ERROR: Unable to find an ${model} connected in a suitable mode"
	exit 1
fi
