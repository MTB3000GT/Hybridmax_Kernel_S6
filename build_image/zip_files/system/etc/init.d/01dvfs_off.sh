#!/system/bin/sh

# Copyright (c) 2013-2015 Hybridmax
#
# DVFS Disabler for Samsung Exynos (Mali) Devices Like Note4, 5, S6, S6-Edge, Plus.
# This Script will not work on other Devices, without mali based CPU.

BB=/xbin/busybox

$BB echo "0" > /sys/devices/14ac0000.mali/dvfs
$BB echo "0" > /sys/devices/14ac0000.mali/dvfs_min_lock
$BB echo "0" > /sys/devices/14ac0000.mali/dvfs_max_lock
$BB echo "0" > /sys/devices/14ac0000.mali/dvfs_governor
$BB echo "0" > /sys/devices/14ac0000.mali/dvfs_min_lock_status
$BB echo "0" > /sys/devices/14ac0000.mali/dvfs_max_lock_status
$BB echo "0" > /sys/devices/14ac0000.mali/dvfs_table

chmod 000 /sys/devices/14ac0000.mali/dvfs
chmod 000 /sys/devices/14ac0000.mali/dvfs_min_lock
chmod 000 /sys/devices/14ac0000.mali/dvfs_max_lock
chmod 000 /sys/devices/14ac0000.mali/dvfs_governor
chmod 000 /sys/devices/14ac0000.mali/dvfs_min_lock_status
chmod 000 /sys/devices/14ac0000.mali/dvfs_max_lock_status
chmod 000 /sys/devices/14ac0000.mali/dvfs_table

# To enable dvfs use this:
#$BB echo "1" > /sys/devices/14ac0000.mali/dvfs
#$BB echo "1" > /sys/devices/14ac0000.mali/dvfs_min_lock
#$BB echo "1" > /sys/devices/14ac0000.mali/dvfs_max_lock
#$BB echo "1" > /sys/devices/14ac0000.mali/dvfs_governor
#$BB echo "1" > /sys/devices/14ac0000.mali/dvfs_min_lock_status
#$BB echo "1" > /sys/devices/14ac0000.mali/dvfs_max_lock_status
#$BB echo "1" > /sys/devices/14ac0000.mali/dvfs_table

#chmod 644 /sys/devices/14ac0000.mali/dvfs
#chmod 644 /sys/devices/14ac0000.mali/dvfs_min_lock
#chmod 644 /sys/devices/14ac0000.mali/dvfs_max_lock
#chmod 644 /sys/devices/14ac0000.mali/dvfs_governor
#chmod 644 /sys/devices/14ac0000.mali/dvfs_min_lock_status
#chmod 644 /sys/devices/14ac0000.mali/dvfs_max_lock_status
#chmod 644 /sys/devices/14ac0000.mali/dvfs_table
