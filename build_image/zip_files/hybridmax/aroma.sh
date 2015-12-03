#!/sbin/sh

if [ "$1" = "WAIT" ]; then	
	sleep 0.7
elif [ "$1" = "FLASH" ]; then	
	dd if=/tmp/boot.img of=/dev/block/platform/15570000.ufs/by-name/BOOT
elif [ "$1" = "FIX_PERMS" ]; then	
	chmod 644 /system/build.prop
	chmod 755 /system/bin/cellgeofenced
	chmod 755 /system/bin/rild
	chmod 644 /system/kernel.prop
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
#elif [ "$1" = "PATCH" ]; then	
#	if [ "`grep "G920T" /proc/cmdline`" != "" ]; then
#		# found G920 T variant	
#		cp /tmp/TLTE/etc/* /system/etc/
#		cp -r /tmp/systemT/* /system/
#	elif [ "`grep "G920W8" /proc/cmdline`" != "" ]; then
#		# found G920 W8 variant	
#		cp -r /tmp/systemT/* /system/
#	elif [ "`grep "G925W8" /proc/cmdline`" != "" ]; then
#		# found G925 W8 variant	
#		cp -r /tmp/systemT/* /system/
#	elif [ "`grep "G925T" /proc/cmdline`" != "" ]; then
#		# found G925 T variant	
#		cp /tmp/TLTE/etc/* /system/etc/
#		cp -r /tmp/systemT/* /system/
#	else
#		# found international variant
#		cp -r /tmp/systemF/* /system/
#	fi
#	chmod 0755 /system/bin/rild
#	chmod 0755 /system/bin/cellgeofenced


##### OPTIONAL CONFIGURATIONS START HERE
elif [ "$1" = "CFQ" ]; then
	echo "kernel.scheduler=cfq" >> /system/kernel.prop

elif [ "$1" = "BFQ" ]; then
	echo "kernel.scheduler=bfq" >> /system/kernel.prop

elif [ "$1" = "DEADLINE" ]; then
	echo "kernel.scheduler=deadline" >> /system/kernel.prop

elif [ "$1" = "FIOPS" ]; then
	echo "kernel.scheduler=fiops" >> /system/kernel.prop

elif [ "$1" = "NOOP" ]; then
	echo "kernel.scheduler=noop" >> /system/kernel.prop

elif [ "$1" = "TURBO" ]; then
	echo "kernel.turbo=true" >> /system/kernel.prop

elif [ "$1" = "NO_TURBO" ]; then
	echo "kernel.turbo=false" >> /system/kernel.prop

elif [ "$1" = "PERF_INTERACTIVE" ]; then
	echo "kernel.interactive=performance" >> /system/kernel.prop

elif [ "$1" = "BATT_INTERACTIVE" ]; then
	echo "kernel.interactive=battery" >> /system/kernel.prop

elif [ "$1" = "STOCK_INTERACTIVE" ]; then
	echo "kernel.interactive=stock" >> /system/kernel.prop

elif [ "$1" = "DHA_VM" ]; then
	bp="/system/build.prop"
	sed -i "/ro.config.sdha/d" $bp
	sed -i "/ro.config.dha/d" $bp
	sed -i "/ro.config.ldha/d" $bp
	sed -i "/ro.config.fha/d" $bp
	sed -i "/ro.sys.fw/d" $bp
	sed -i "/kernel.vm/d" /system/kernel.prop
	sed -i "/Kernel/d" $bp
	echo "ro.config.dha_cached_max=16" >> $bp 
	echo "ro.config.dha_cached_min=10" >> $bp
	echo "ro.config.dha_empty_min=8" >> $bp
	echo "ro.config.dha_empty_max=25" >> $bp
	echo "ro.config.dha_lmk_scale=1" >> $bp
	echo "ro.config.dha_th_rate=1" >> $bp
	echo "kernel.vm=tuned" >> /system/kernel.prop

elif [ "$1" = "FHA_VM" ]; then
	bp="/system/build.prop"
	sed -i "/ro.config.sdha/d" $bp
	sed -i "/ro.config.dha/d" $bp
	sed -i "/ro.config.ldha/d" $bp
	sed -i "/ro.config.fha/d" $bp
	sed -i "/ro.sys.fw/d" $bp
	sed -i "/kernel.vm/d" /system/kernel.prop
	sed -i "/Kernel/d" $bp
	echo "ro.config.fha_enable=true" >> $bp
	echo "kernel.vm=tuned" >> /system/kernel.prop

elif [ "$1" = "STOCK_VM" ]; then
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
	bp="/system/build.prop"
	sed -i "/ro.config.sdha/d" $bp
	sed -i "/ro.config.dha/d" $bp
	sed -i "/ro.config.ldha/d" $bp
	sed -i "/ro.config.fha/d" $bp
	sed -i "/ro.sys.fw/d" $bp
	sed -i "/kernel.vm/d" /system/kernel.prop
	sed -i "/Kernel/d" $bp
	#set stock device specific DHA - F variants are different to T variants
	if [ "$D" = "F" ]; then
		echo "ro.config.dha_cached_min=4" >> $bp
		echo "ro.config.dha_empty_min=8" >> $bp
		echo "ro.config.dha_lmk_scale=1.909" >> $bp
	else
		echo "ro.config.dha_cached_max=6" >> $bp
		echo "ro.config.dha_cached_min=3" >> $bp
		echo "ro.config.dha_empty_max=30" >> $bp
		echo "ro.config.dha_empty_min=8" >> $bp
		echo "ro.config.dha_lmk_scale=1.909" >> $bp
		echo "ro.config.dha_th_rate=2.0" >> $bp
	fi
	echo "kernel.vm=stock" >> /system/kernel.prop

elif [ "$1" = "AUTO_INITD" ]; then
	echo "kernel.initd=true" >> /system/kernel.prop

elif [ "$1" = "NO_INITD" ]; then
	echo "kernel.initd=false" >> /system/kernel.prop

elif [ "$1" = "FIX_GAPPS" ]; then
	echo "kernel.gapps=true" >> /system/kernel.prop

elif [ "$1" = "STOCK_GAPPS" ]; then
	echo "kernel.gapps=false" >> /system/kernel.prop

###
### ADD OTHER OPTIONS AS THEY ARE CREATED HERE
###

fi

