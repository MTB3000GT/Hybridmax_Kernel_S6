#!/sbin/sh
# Copyright (c) g.lewarne@xda
#           (c) Hybridmax (hybridmax95@gmail.com)
#           (c) thehacker911 (Maik.Diebenkorn@gmail.com)
#
# This Aroma Package Kernel-Installer was created by g.lewarne@xda
# You can use and modify it by our needs.
# Please give the Credits to him!
#
# This is a info file for rom developer.
# Rom developer can create a kernel profile too.
# Create a file with the name "kernel.prop" under system Directory. (/system/kernel.prop)
# Add your kernel settings into the file kernel.prop
#
#------------------------------------------
# Example:
# kernel.scheduler=cfq
#------------------------------------------
#
# None of the kernel settings must be present twice!
#
#------------------------------------------
# Example GOOD kernel settings:
# kernel.scheduler=cfq
#
# Example BAD kernel settings:
# kernel.scheduler=cfq
# kernel.scheduler=bfq
#------------------------------------------
#
# Happy tweaking ;)
#
#------------------------------------------
#
# Example kernel settings
# SCHEDULER (set your scheduler)
#
# CFQ
# kernel.scheduler=cfq   --->   /system/kernel.prop
#
# DEADLINE
# kernel.scheduler=deadline   --->   /system/kernel.prop
#
# NOOP
# kernel.scheduler=noop   --->   /system/kernel.prop
#----------------------------
# Governor
#
# CONSERVATIVE
# kernel.governor=conservative   --->   /system/kernel.prop
#
# INTERACTIVE
# kernel.governor=interactive   --->   /system/kernel.prop
#
# ONDEMAND
# kernel.governor=ondemand   --->   /system/kernel.prop
#
# PERFORMANCE
# kernel.governor=performance   --->   /system/kernel.prop
#
# USERSPACE
# kernel.governor=userspace   --->   /system/kernel.prop
#----------------------------
# TURBO (set turbo mod on)
# kernel.turbo=true   --->   /system/kernel.prop
#
# NO_TURBO (set turbo mod 0ff)
# kernel.turbo=false   --->   /system/kernel.prop
#----------------------------
# AUTO_INITD (init.d if Auto or ROM control)
# kernel.initd=true   --->   /system/kernel.prop
#
# NO_INITD
# kernel.initd=false   --->   /system/kernel.prop
#----------------------------
# FIX_GAPPS (GApps wakelock fix)
# kernel.gapps=true (set GApps wakelock fix on)   --->   /system/kernel.prop
#
# kernel.gapps=false (set GApps wakelock fix off)   --->   /system/kernel.prop
#----------------------------
# KNOX (remove knox apks)
# kernel.knox=true   --->   /system/kernel.prop
#------------------------------------------
#
# default kernel setting in aroma
#
#----------------------------
# Stock Settings
#
# kernel.scheduler=cfq
# kernel.turbo=false
# kernel.governor=interactive
# kernel.initd=false
# kernel.gapps=false 
#
#----------------------------
# PERFORMANCE Settings
#
# kernel.scheduler=bfq
# kernel.turbo=true
# kernel.governor=performance
# kernel.initd=true
# kernel.gapps=false 
#
#----------------------------
# BATTERY Settings
#
# kernel.scheduler=noop
# kernel.turbo=false
# kernel.governor=interactive
# kernel.initd=false
# kernel.gapps=true
#
#------------------------------------------
#
# End of Read me

