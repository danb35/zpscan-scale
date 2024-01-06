#!/usr/bin/bash
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

# If no errors, clear locate/fault LEDs and exit
if [ $(/usr/sbin/zpool status | grep -cE "(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED)") -eq 0 ]; then
  "${encled}" ALL off
  exit 0
fi

# If we're here, there's a pool error.  Find the faulted device(s) and
# light the corresponding LEDs
errors_file=$(mktemp)
/usr/sbin/zpool status | grep -E "(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED)" > "${errors_file}"
while read -r line; do
  device=$(echo "${line}" | awk '{print $1}')
  device_alpha=$(lsblk -o NAME,SIZE,PARTUUID | grep "${device}" | awk '{print $1}' | tr -cd [:alpha:])
  if ! [ "${device_alpha}" = "" ]; then
    "${encled}" "${device_alpha}" fault
  fi
done < "${errors_file}"

# Delete the temp file
rm "${errors_file}"
