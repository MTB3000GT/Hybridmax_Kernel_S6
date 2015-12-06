#!/sbin/sh

# Aroma-Installer Kernel Tune Script
#
# Copyright (c) g.lewarne@xda
#           (c) Hybridmax (hybridmax95@gmail.com)
#           (c) thehacker911 (maik.diebenkorn@gmail.com)
#
# This Script based on g.lewarnes Script.
# It was modified for my need.

#vars
PROP=/system/kernel.prop
BP=/system/build.prop

if [ "$1" = "WAIT" ]; then	
	sleep 0.7
elif [ "$1" = "FLASH" ]; then	
	dd if=/tmp/boot.img of=/dev/block/platform/15570000.ufs/by-name/BOOT
elif [ "$1" = "FIX_PERMS" ]; then	
	chmod 644 $BP
	chmod 644 $PROP
elif [ "$1" = "DETECT" ]; then	
	# Probe /proc/cmdline to detect variant
	if [ "`grep "G920T" /proc/cmdline`" != "" ]; then
		# found G920 T variant	
		D=T
	elif [ "`grep "G920W8" /proc/cmdline`" != "" ]; then
		# found G920 W8 variant	
		D=T
	elif [ "`grep "G925T" /proc/cmdline`" != "" ]; then
		# found G925 T variant	
		D=T
	elif [ "`grep "G925W8" /proc/cmdline`" != "" ]; then
		# found G925 W8 variant	
		D=T
	elif [ "`grep "G920P" /proc/cmdline`" != "" ]; then
		# found G920 P variant
		D=P
	elif [ "`grep "G925P" /proc/cmdline`" != "" ]; then
		# found G925 P variant
		D=P
	elif [ "`grep "G920R" /proc/cmdline`" != "" ]; then
		# found G925 R variant
		D=P
	elif [ "`grep "G925R" /proc/cmdline`" != "" ]; then
		# found G925 R variant
		D=P
	else
		# must be an international variant, assume F
		D=F
	fi
	if [ "$D" = "P" ]; then
		echo "device.type=incompatible" > /system/device.prop
	else
		echo "device.type=compatible" > /system/device.prop
	fi
	if [ "$D" = "F" ]; then
		if [ "`grep "G925" /proc/cmdline`" != "" ]; then
			echo "device.model=intedgeF" >> /system/device.prop
		else
			echo "device.model=intflatF" >> /system/device.prop
		fi
	else
		if [ "`grep "G925" /proc/cmdline`" != "" ]; then
			echo "device.model=intedgeT" >> /system/device.prop
		else
			echo "device.model=intflatT" >> /system/device.prop
		fi
	fi
	sleep 0.7

# SCHEDULER
elif [ "$1" = "CFQ" ]; then
	echo "kernel.scheduler=cfq" >> $PROP

elif [ "$1" = "BFQ" ]; then
	echo "kernel.scheduler=bfq" >> $PROP

elif [ "$1" = "DEADLINE" ]; then
	echo "kernel.scheduler=deadline" >> $PROP

elif [ "$1" = "FIOPS" ]; then
	echo "kernel.scheduler=fiops" >> $PROP

elif [ "$1" = "NOOP" ]; then
	echo "kernel.scheduler=noop" >> $PROP

# GOVS
elif [ "$1" = "CONSERVATIVE" ]; then
	echo "kernel.governor=conservative" >> $PROP

elif [ "$1" = "INTERACTIVE" ]; then
	echo "kernel.governor=interactive" >> $PROP

elif [ "$1" = "ONDEMAND" ]; then
	echo "kernel.governor=ondemand" >> $PROP

elif [ "$1" = "PERFORMANCE" ]; then
	echo "kernel.governor=performance" >> $PROP
sleep 0.7

# CPU CLOCK A53
elif [ "$1" = "A53-400" ]; then
	echo "kernel.cpu.a53.min=400000" >> $PROP

elif [ "$1" = "A53-1200" ]; then
	echo "kernel.cpu.a53.max=1200000" >> $PROP

elif [ "$1" = "A53-1296" ]; then
	echo "kernel.cpu.a53.max=1296000" >> $PROP

elif [ "$1" = "A53-1400" ]; then
	echo "kernel.cpu.a53.max=1400000" >> $PROP

elif [ "$1" = "A53-1500" ]; then
	echo "kernel.cpu.a53.max=1500000" >> $PROP
sleep 0.7

# CPU CLOCK A57
elif [ "$1" = "A57-800" ]; then
	echo "kernel.cpu.a57.min=800000" >> $PROP

elif [ "$1" = "A57-1704" ]; then
	echo "kernel.cpu.a57.max=1704000" >> $PROP

elif [ "$1" = "A57-1800" ]; then
	echo "kernel.cpu.a57.max=1800000" >> $PROP

elif [ "$1" = "A57-1896" ]; then
	echo "kernel.cpu.a57.max=1896000" >> $PROP

elif [ "$1" = "A57-2000" ]; then
	echo "kernel.cpu.a57.max=2000000" >> $PROP

elif [ "$1" = "A57-2100" ]; then
	echo "kernel.cpu.a57.max=2100000" >> $PROP
sleep 0.7

# TURBO MODE
elif [ "$1" = "TURBO" ]; then
	echo "kernel.turbo=true" >> $PROP

elif [ "$1" = "NO_TURBO" ]; then
	echo "kernel.turbo=false" >> $PROP

# AUTOMATIC INITD CONTROL
elif [ "$1" = "AUTO_INITD" ]; then
	echo "kernel.initd=true" >> $PROP

elif [ "$1" = "NO_INITD" ]; then
	echo "kernel.initd=false" >> $PROP

# GAPPS WAKELOCK FIX
elif [ "$1" = "FIX_GAPPS" ]; then
	echo "kernel.gapps=true" >> $PROP

elif [ "$1" = "STOCK_GAPPS" ]; then
	echo "kernel.gapps=false" >> $PROP

# REMOVE KNOX
elif [ "$1" = "KNOX" ]; then
	echo "kernel.knox=true" >> $PROP

fi

