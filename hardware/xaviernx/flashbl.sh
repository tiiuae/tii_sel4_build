#! /bin/sh

set -e

cd ~/Linux_for_Tegra

cat <<EOF
Step 1: flashing the A-side bootloader

Make sure forced recovery jumper is ON, then power cycle the board
and press enter.
EOF
read p

sudo ./flash.sh -k cpu-bootloader -L bootloader/cboot_t194.bin jetson-xavier-nx-devkit mmcblk0p1

cat <<EOF
Step 2: flashing the B-side bootloader

Power cycle the board again and press enter.
EOF
read p

sudo ./flash.sh -k cpu-bootloader_b -L bootloader/cboot_t194.bin jetson-xavier-nx-devkit mmcblk0p1

cat <<EOF
Step 3: flashing the bootloader configuration

Power cycle the board again and press enter.
EOF
read p

sudo ./flash.sh -r -k CPUBL-CFG --image bootloader/cbo.dtb jetson-xavier-nx-devkit mmcblk0p1

cat <<EOF
Done! Power off the board and remove the forced recovery jumper.
EOF
