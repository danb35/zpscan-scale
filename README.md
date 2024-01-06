# zpscan-scale
This is a script to monitor your ZFS pools in TrueNAS SCALE, and light up the FAULT LED on compatible SAS backplanes when a disk fails or otherwise goes offline.

# WARNING
This script has had very minimal testing and should not be relied on for production use.

## Requirements
This script is only intended to run under TrueNAS SCALE, and has only been tested under version 23.10.1.  It **will not** work under TrueNAS CORE.  It may work under other Linux installations, but most likely only if you have created your pool using gptid designators.

This script relies on [encled](https://github.com/amarao/sdled).  `git clone` that repository to some place on your server.

## Installation
`git clone` this repository to a convenient place on your system.

## Configuration
Change to this repository's directory, and `cp zpscan-config.example zpscan-config`.  Then edit `zpscan-config` and set the path to the `encled` script there.

## Usage
In the TrueNAS web UI, set a cron job to run the `zpscan-scale.sh` script on your desired schedule; I'd suggest somewhere between every 15 minutes and every hour.

