#!/bin/sh
# https://github.com/danb35/zpscan-scale

# Scan TrueNAS SCALE pools for faulted disks, and light the Fault LED
# on a compatible backplane.

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Initialize configuration
encled=""
CONFIG_NAME="zpscan-config"

# Check for zpscan-config and set configuration
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
if ! [ -e "${SCRIPTPATH}"/"${CONFIG_NAME}" ]; then
  echo "${SCRIPTPATH}/${CONFIG_NAME} must exist."
  exit 1
fi
. "${SCRIPTPATH}"/"${CONFIG_NAME}"

# Check that path to encled script is set
if [ -z "${encled}" ]; then
  echo 'Configuration error: \"encled\" must be set in zpscan-config'
  exit 1
fi

# check that encled exists
if ! [ -f "${encled}" ]; then
  echo "${encled} not found!"
  exit 1
fi

# Create temp file and save zpool status to it
status_file=$(mktemp)
/usr/sbin/zpool status > "${status_file}"

# If no errors, clear locate/fault LEDs, remove temp file, and exit
if [ $(cat "${status_file}" | grep -E "(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED)" | wc -l) -eq 0 ]; then
  "${encled}" ALL off
  rm "${status_file}"
  exit 0
fi

# If we're here, there's a pool error.  Find the faulted device(s) and
# light the corresponding LEDs
errors=$(cat "${status_file}" | grep -E "(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED)")
for line in "${errors}"; do
  echo "line: ${line}"
  device=$(echo "${line}" | awk '{print $1}')
  echo "device: ${device}"
  device_alpha=$(lsblk -o NAME,SIZE,PARTUUID | grep "${device}" | awk '{print $1}' | tr -cd [:alpha:])
  echo "device_alpha: ${device_alpha}"
  if ! [ "${device_alpha}" = ""]; then
    "${encled}" "${device_alpha}" fault
  fi
done

# Delete the temp file
rm "${status_file}"
