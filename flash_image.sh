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
	echo "Note that you may have to accept an ADB prompt and/or a MagiskSU authorisation prompt first"
fi

readonly sync='sync ; echo 3 > /proc/sys/vm/drop_caches ; sync'
readonly SHA1=($(sha1sum "${recovery_image}"))
if [ -z "$SHA1" ]; then
	echo "ERROR: Unable to determine SHA1 of ${recovery_image}"
	exit 1
fi

if [ "$mode" = "recovery" ]; then
	readonly dest="/tmp"
	readonly remote="${dest}/${recovery_basename}"
	adb -s "$serial" push "$recovery_image" "$dest/"
	if [ "$SHA1" != "$(adb -s "$serial" shell "sha1sum \"${remote}\"" | awk '{print $1}')" ]; then # Works under TWRP with toybox as default, busybox should be fine
		echo "ERROR: pushed ${recovery_image}'s sha1sum does not match $SHA1"
		exit 1
	fi
	adb -s "$serial" shell "sh -c 'cat \"${remote}\" /dev/zero >/dev/block/by-name/recovery 2>/dev/null && $sync ; reboot recovery'"
elif [ "$mode" = "device" ]; then
	readonly dest="/data/local/tmp"
	readonly remote="${dest}/${recovery_basename}"
	#if [ "$SHA1" != "$(adb -s "$serial" shell "sha1sum \"${remote}\"" 2>/dev/null| awk '{print $1}')" ]; then # toybox sha1sum has the -b option, busybox's doesn't
		adb -s "$serial" push "$recovery_image" "$dest/"
		if [ "$SHA1" != "$(adb -s "$serial" shell "sha1sum \"${remote}\"" | awk '{print $1}')" ]; then
			echo "ERROR: pushed ${recovery_image}'s sha1sum does not match $SHA1"
			exit 1
		fi
	#fi
	adb -s "$serial" shell "su -c 'cat \"${remote}\" /dev/zero >/dev/block/by-name/recovery 2>/dev/null && $sync ; rm -f \"${remote}\" ; svc power reboot recovery'"
else
	#Heimdall 1.4.2 doesn't work for the S10+ under Ubuntu, so if you can't even get to TWRP, Odin in Windows is your only option
	echo "ERROR: Unable to find an ${model} connected in a suitable mode"
	exit 1
fi
