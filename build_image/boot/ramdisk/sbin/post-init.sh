#!/system/xbin/busybox sh

# Kernel Tuning by Hybridmax

#vars
BB=/system/xbin/busybox
PROP=/system/kernel.prop
GOVLITTLE=/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
GOVBIG=/sys/devices/system/cpu/cpu4/cpufreq/scaling_governor
FREQMINLITTLE1=/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
FREQMINLITTLE2=/sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq
FREQMINLITTLE3=/sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq
FREQMINLITTLE4=/sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq
FREQMAXLITTLE1=/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
FREQMAXLITTLE2=/sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq
FREQMAXLITTLE3=/sys/devices/system/cpu/cpu2/cpufreq/scaling_max_freq
FREQMAXLITTLE4=/sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
FREQMINBIG1=/sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
FREQMINBIG2=/sys/devices/system/cpu/cpu5/cpufreq/scaling_min_freq
FREQMINBIG3=/sys/devices/system/cpu/cpu6/cpufreq/scaling_min_freq
FREQMINBIG4=/sys/devices/system/cpu/cpu7/cpufreq/scaling_min_freq
FREQMAXBIG1=/sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
FREQMAXBIG2=/sys/devices/system/cpu/cpu5/cpufreq/scaling_max_freq
FREQMAXBIG3=/sys/devices/system/cpu/cpu6/cpufreq/scaling_max_freq
FREQMAXBIG4=/sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq
DATE=$(date)
LOG=/data/.hybridmax/Hybridmax-Kernel.log

###############################################################################
# Open Partitions in writable mode

$BB mount -o remount,rw /system
$BB mount -o remount,rw /data
$BB mount -o remount,rw /
sync

###############################################################################
# Parse Mode Enforcement from prop

if [ "`grep "kernel.turbo=true" $PROP`" != "" ]; then
	echo "1" > /sys/devices/system/cpu/cpu0/cpufreq/interactive/enforced_mode
	echo "1" > /sys/devices/system/cpu/cpu4/cpufreq/interactive/enforced_mode
fi

###############################################################################
# Wait for 5 second so we pass out of init before starting the rest of the script

sleep 5

###############################################################################
# Start SuperSU daemon

/system/xbin/daemonsu --auto-daemon &

###############################################################################
# Make internal storage directory.

if [ ! -d /data/.hybridmaxkernel ]; then
	mkdir /data/.hybridmax
	chmod 0777 /data/.hybridmax
else
	rm -rf /data/.hybridmax/*
	chmod 0777 /data/.hybridmax
fi;

###############################################################################
# Create Log File

$BB touch $LOG
echo "$DATE" >> $LOG
echo "" >> $LOG
echo "=========================" >> $LOG
echo "System Informations:" >> $LOG
$BB grep ro.build.display.id /system/build.prop >> $LOG
$BB grep ro.product.model /system/build.prop >> $LOG
$BB grep ro.build.version /system/build.prop >> $LOG
$BB grep ro.product.board /system/build.prop >> $LOG
echo "=========================" >> $LOG
echo "" >> $LOG

###############################################################################
# Clean old modules from /system and add new from ramdisk

if [ ! -d /system/lib/modules ]; then
	$BB mkdir /system/lib/modules
else
	$BB rm -rf /system/lib/modules
	$BB cp -a /lib/modules/*.ko /system/lib/modules/
	$BB chmod 755 /system/lib/modules/*.ko
fi

###############################################################################
# Parse init/d support from prop

if [ "`grep "kernel.initd=true" $PROP`" != "" ]; then
	if [ -d /system/etc/init.d ]; then
		chmod 755 /system/etc/init.d
		chmod 755 /system/etc/init.d/*
		run-parts /system/etc/init.d
	else
		mkdir /system/etc/init.d
		chmod 755 /system/etc/init.d
	fi
	echo "init.d Support enabled successful." >> $LOG
fi

###############################################################################
# Tune entropy parameters.

echo "512" > /proc/sys/kernel/random/read_wakeup_threshold
echo "256" > /proc/sys/kernel/random/write_wakeup_threshold
echo "entropy parameters tuned." >> $LOG

###############################################################################
# No cache flush allowed for write protected devices

echo "temporary none" > /sys/class/scsi_disk/0:0:0:1/cache_type
echo "temporary none" > /sys/class/scsi_disk/0:0:0:2/cache_type
echo "cache flush disabled." >> $LOG

###############################################################################
# Synapse Configuration

$BB mount -t rootfs -o remount,rw rootfs
$BB chmod -R 755 /res/synapse
$BB ln -fs /res/synapse/uci /sbin/uci
/sbin/uci
$BB mount -t rootfs -o remount,ro rootfs

#Synapse profile
if [ ! -f /data/.hybridmax/bck_prof ]; then
	cp -f /res/synapse/files/bck_prof /data/.hybridmax/bck_prof
fi

chmod 777 /data/.hybridmax/bck_prof

###############################################################################
# Critical Permissions fix

$BB chown -R root:root /tmp
$BB chown -R root:root /res
$BB chown -R root:root /sbin
$BB chown -R root:root /lib
$BB chmod -R 777 /tmp/
$BB chmod -R 775 /res/
$BB chmod -R 06755 /sbin/ext/
$BB chmod 06755 /sbin/busybox
$BB chmod 06755 /system/xbin/busybox
echo "Fixing Permissions" >> $LOG

###############################################################################
# Parse Interactive tuning from prop

if [ "`grep "kernel.interactive=performance" $PROP`" != "" ]; then
	# apollo	
	echo "12000"	> /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay
	echo "45000"	> /sys/devices/system/cpu/cpu0/cpufreq/interactive/boostpulse_duration
	echo "80"	> /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load
	echo "1"	> /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
	echo "70"	> /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
	echo "35000"	> /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time
	echo "20000"	> /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate
	# atlas
	echo "25000 1300000:20000 1700000:20000" > /sys/devices/system/cpu/cpu4/cpufreq/interactive/above_hispeed_delay
	echo "45000"	> /sys/devices/system/cpu/cpu4/cpufreq/interactive/boostpulse_duration
	echo "83"	> /sys/devices/system/cpu/cpu4/cpufreq/interactive/go_hispeed_load
	echo "1"	> /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
	echo "60 1500000:70"	> /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
	echo "35000"	> /sys/devices/system/cpu/cpu4/cpufreq/interactive/min_sample_time
	echo "15000"	> /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_rate
elif [ "`grep "kernel.interactive=battery" $PROP`" != "" ]; then
	# apollo	
	echo "37000"	> /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay
	echo "25000"	> /sys/devices/system/cpu/cpu0/cpufreq/interactive/boostpulse_duration
	echo "80"	> /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load
	echo "0"	> /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
	echo "90"	> /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
	echo "15000"	> /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time
	echo "15000"	> /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate
	# atlas
	echo "70000 1300000:55000 1700000:55000" > /sys/devices/system/cpu/cpu4/cpufreq/interactive/above_hispeed_delay
	echo "25000"	> /sys/devices/system/cpu/cpu4/cpufreq/interactive/boostpulse_duration
	echo "95"	> /sys/devices/system/cpu/cpu4/cpufreq/interactive/go_hispeed_load
	echo "0"	> /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
	echo "80 1500000:90"	> /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
	echo "15000"	> /sys/devices/system/cpu/cpu4/cpufreq/interactive/min_sample_time
	echo "15000"	> /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_rate
fi

sleep 5

###############################################################################
# Parse IO Scheduler from prop

if [ "`grep "kernel.scheduler=noop" $PROP`" != "" ]; then
	echo "noop" > /sys/block/mmcblk0/queue/scheduler
    	echo "noop" > /sys/block/sda/queue/scheduler
    	echo "noop" > /sys/block/sdb/queue/scheduler
    	echo "noop" > /sys/block/sdc/queue/scheduler
    	echo "noop" > /sys/block/vnswap0/queue/scheduler
elif [ "`grep "kernel.scheduler=fiops" $PROP`" != "" ]; then
	echo "fiops" > /sys/block/mmcblk0/queue/scheduler
    	echo "fiops" > /sys/block/sda/queue/scheduler
    	echo "fiops" > /sys/block/sdb/queue/scheduler
    	echo "fiops" > /sys/block/sdc/queue/scheduler
    	echo "fiops" > /sys/block/vnswap0/queue/scheduler
elif [ "`grep "kernel.scheduler=deadline" $PROP`" != "" ]; then
	echo "deadline" > /sys/block/mmcblk0/queue/scheduler
    	echo "deadline" > /sys/block/sda/queue/scheduler
    	echo "deadline" > /sys/block/sdb/queue/scheduler
    	echo "deadline" > /sys/block/sdc/queue/scheduler
    	echo "deadline" > /sys/block/vnswap0/queue/scheduler
elif [ "`grep "kernel.scheduler=bfq" $PROP`" != "" ]; then
	echo "bfq" > /sys/block/mmcblk0/queue/scheduler
    	echo "bfq" > /sys/block/sda/queue/scheduler
    	echo "bfq" > /sys/block/sdb/queue/scheduler
    	echo "bfq" > /sys/block/sdc/queue/scheduler
    	echo "bfq" > /sys/block/vnswap0/queue/scheduler
elif [ "`grep "kernel.scheduler=cfg" $PROP`" != "" ]; then
	echo "cfq" > /sys/block/mmcblk0/queue/scheduler
    	echo "cfq" > /sys/block/sda/queue/scheduler
    	echo "cfq" > /sys/block/sdb/queue/scheduler
    	echo "cfq" > /sys/block/sdc/queue/scheduler
    	echo "cfq" > /sys/block/vnswap0/queue/scheduler
else
	echo "cfq" > /sys/block/mmcblk0/queue/scheduler
    	echo "cfq" > /sys/block/sda/queue/scheduler
    	echo "cfq" > /sys/block/sdb/queue/scheduler
    	echo "cfq" > /sys/block/sdc/queue/scheduler
    	echo "cfq" > /sys/block/vnswap0/queue/scheduler
fi

###############################################################################
# Parse Governor from prop

if [ "`grep "kernel.governor=conservative" $PROP`" != "" ]; then
	echo "conservative" > $GOVLITTLE
	echo "conservative" > $GOVBIG
elif [ "`grep "kernel.governor=interactive" $PROP`" != "" ]; then
	echo "interactive" > $GOVLITTLE
	echo "interactive" > $GOVBIG
elif [ "`grep "kernel.governor=ondemand" $PROP`" != "" ]; then
	echo "ondemand" > $GOVLITTLE
	echo "ondemand" > $GOVBIG
elif [ "`grep "kernel.governor=performance" $PROP`" != "" ]; then
	echo "performance" > $GOVLITTLE
	echo "performance" > $GOVBIG
else 
	echo "interactive" > $GOVLITTLE
	echo "interactive" > $GOVBIG
fi

###############################################################################
# Parse CPU CLOCK from prop

if [ "`grep "kernel.cpu.a53.min=400000" $PROP`" != "" ]; then
	echo "400000" > $FREQMINLITTLE1
	echo "400000" > $FREQMINLITTLE2
	echo "400000" > $FREQMINLITTLE3
	echo "400000" > $FREQMINLITTLE4
else
	echo "400000" > $FREQMINLITTLE1
	echo "400000" > $FREQMINLITTLE2
	echo "400000" > $FREQMINLITTLE3
	echo "400000" > $FREQMINLITTLE4
fi

sleep 1;

if [ "`grep "kernel.cpu.a53.max=1200000" $PROP`" != "" ]; then
	echo "1200000" > $FREQMAXLITTLE1
	echo "1200000" > $FREQMAXLITTLE2
	echo "1200000" > $FREQMAXLITTLE3
	echo "1200000" > $FREQMAXLITTLE4
elif [ "`grep "kernel.cpu.a53.min=1296000" $PROP`" != "" ]; then
	echo "1296000" > $FREQMAXLITTLE1
	echo "1296000" > $FREQMAXLITTLE2
	echo "1296000" > $FREQMAXLITTLE3
	echo "1296000" > $FREQMAXLITTLE4
elif [ "`grep "kernel.cpu.a53.min=1400000" $PROP`" != "" ]; then
	echo "1400000" > $FREQMAXLITTLE1
	echo "1400000" > $FREQMAXLITTLE2
	echo "1400000" > $FREQMAXLITTLE3
	echo "1400000" > $FREQMAXLITTLE4
elif [ "`grep "kernel.cpu.a53.min=1500000" $PROP`" != "" ]; then
	echo "1500000" > $FREQMAXLITTLE1
	echo "1500000" > $FREQMAXLITTLE2
	echo "1500000" > $FREQMAXLITTLE3
	echo "1500000" > $FREQMAXLITTLE4
else
	echo "1500000" > $FREQMAXLITTLE1
	echo "1500000" > $FREQMAXLITTLE2
	echo "1500000" > $FREQMAXLITTLE3
	echo "1500000" > $FREQMAXLITTLE4
fi

sleep 1;

if [ "`grep "kernel.cpu.a57.min=800000" $PROP`" != "" ]; then
	echo "800000" > $FREQMINBIG1
	echo "800000" > $FREQMINBIG2
	echo "800000" > $FREQMINBIG3
	echo "800000" > $FREQMINBIG4
else
	echo "800000" > $FREQMINBIG1
	echo "800000" > $FREQMINBIG2
	echo "800000" > $FREQMINBIG3
	echo "800000" > $FREQMINBIG4
fi

sleep 1;

if [ "`grep "kernel.cpu.a57.max=1704000" $PROP`" != "" ]; then
	echo "1704000" > $FREQMAXBIG1
	echo "1704000" > $FREQMAXBIG2
	echo "1704000" > $FREQMAXBIG3
	echo "1704000" > $FREQMAXBIG4
elif [ "`grep "kernel.cpu.a57.max=1800000" $PROP`" != "" ]; then
	echo "1800000" > $FREQMAXBIG1
	echo "1800000" > $FREQMAXBIG2
	echo "1800000" > $FREQMAXBIG3
	echo "1800000" > $FREQMAXBIG4
elif [ "`grep "kernel.cpu.a57.max=1896000" $PROP`" != "" ]; then
	echo "1896000" > $FREQMAXBIG1
	echo "1896000" > $FREQMAXBIG2
	echo "1896000" > $FREQMAXBIG3
	echo "1896000" > $FREQMAXBIG4
elif [ "`grep "kernel.cpu.a57.max=2000000" $PROP`" != "" ]; then
	echo "2000000" > $FREQMAXBIG1
	echo "2000000" > $FREQMAXBIG2
	echo "2000000" > $FREQMAXBIG3
	echo "2000000" > $FREQMAXBIG4
elif [ "`grep "kernel.cpu.a57.max=2100000" $PROP`" != "" ]; then
	echo "2100000" > $FREQMAXBIG1
	echo "2100000" > $FREQMAXBIG2
	echo "2100000" > $FREQMAXBIG3
	echo "2100000" > $FREQMAXBIG4
else
	echo "2100000" > $FREQMAXBIG1
	echo "2100000" > $FREQMAXBIG2
	echo "2100000" > $FREQMAXBIG3
	echo "2100000" > $FREQMAXBIG4
fi

sleep 1;


###############################################################################
# Parse VM Tuning from prop

if [ "`grep "kernel.vm=tuned" $PROP`" != "" ]; then
	echo "200"	> /proc/sys/vm/vfs_cache_pressure
	echo "200"	> /proc/sys/vm/dirty_expire_centisecs
	echo "200"	> /proc/sys/vm/dirty_writeback_centisecs
	echo "135"	> /proc/sys/vm/swappiness
	echo "48"	> /sys/block/sda/queue/read_ahead_kb
	echo "48"	> /sys/block/sdb/queue/read_ahead_kb
	echo "48"	> /sys/block/sdb/queue/read_ahead_kb
	echo "48"	> /sys/block/vnswap0/queue/read_ahead_kb
fi

###############################################################################
# Parse KNOX from prop

if [ "`grep "kernel.knox=true" $PROP`" != "" ]; then
	cd /system
	rm -rf *app/BBCAgent*
	rm -rf *app/Bridge*
	rm -rf *app/ContainerAgent*
	rm -rf *app/ContainerEventsRelayManager*
	rm -rf *app/DiagMonAgent*
	rm -rf *app/ELMAgent*
	rm -rf *app/FotaClient*
	rm -rf *app/FWUpdate*
	rm -rf *app/FWUpgrade*
	rm -rf *app/HLC*
	rm -rf *app/KLMSAgent*
	rm -rf *app/*Knox*
	rm -rf *app/*KNOX*
	rm -rf *app/LocalFOTA*
	rm -rf *app/RCPComponents*
	rm -rf *app/SecKids*;
	rm -rf *app/SecurityLogAgent*
	rm -rf *app/SPDClient*
	rm -rf *app/SyncmlDM*
	rm -rf *app/UniversalMDMClient*
	rm -rf container/*Knox*
	rm -rf container/*KNOX*
	echo "KNOX was removed successful." >> $LOG
fi

###############################################################################
# Stop google service and restart it on boot. this remove high cpu load and ram leak!

if [ "$($BB pidof com.google.android.gms | wc -l)" -eq "1" ]; then
	$BB kill "$($BB pidof com.google.android.gms)"
fi;
if [ "$($BB pidof com.google.android.gms.unstable | wc -l)" -eq "1" ]; then
	$BB kill "$($BB pidof com.google.android.gms.unstable)"
fi;
if [ "$($BB pidof com.google.android.gms.persistent | wc -l)" -eq "1" ]; then
	$BB kill "$($BB pidof com.google.android.gms.persistent)"
fi;
if [ "$($BB pidof com.google.android.gms.wearable | wc -l)" -eq "1" ]; then
	$BB kill "$($BB pidof com.google.android.gms.wearable)"
fi

###############################################################################
# Parse GApps wakelock fix from prop

if [ "`grep "kernel.gapps=true" $PROP`" != "" ]; then
	# Google Services battery drain fixer by Alcolawl@xda
	# http://forum.xda-developers.com/google-nexus-5/general/script-google-play-services-battery-t3059585/post59563859
	pm enable com.google.android.gms/.update.SystemUpdateActivity
	pm enable com.google.android.gms/.update.SystemUpdateService
	pm enable com.google.android.gms/.update.SystemUpdateService$ActiveReceiver
	pm enable com.google.android.gms/.update.SystemUpdateService$Receiver
	pm enable com.google.android.gms/.update.SystemUpdateService$SecretCodeReceiver
	pm enable com.google.android.gsf/.update.SystemUpdateActivity
	pm enable com.google.android.gsf/.update.SystemUpdatePanoActivity
	pm enable com.google.android.gsf/.update.SystemUpdateService
	pm enable com.google.android.gsf/.update.SystemUpdateService$Receiver
	pm enable com.google.android.gsf/.update.SystemUpdateService$SecretCodeReceiver
	echo "GApps Fix applied." >> $LOG
fi

###############################################################################
# Script finish here, so let me know when

echo "" >> $LOG
echo "Done, Kernel Tuning finished." >> $LOG
echo "$DATE" >> $LOG

