#!/system/xbin/busybox sh

# Kernel Tuning by Hybridmax

#vars
BB=/system/xbin/busybox
PROP=/system/kernel.prop
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
elif [ "`grep "kernel.scheduler=fiops" $PROP`" != "" ]; then
	echo "fiops" > /sys/block/mmcblk0/queue/scheduler
    	echo "fiops" > /sys/block/sda/queue/scheduler
elif [ "`grep "kernel.scheduler=bfq" $PROP`" != "" ]; then
	echo "bfq" > /sys/block/mmcblk0/queue/scheduler
    	echo "bfq" > /sys/block/sda/queue/scheduler
elif [ "`grep "kernel.scheduler=deadline" $PROP`" != "" ]; then
	echo "deadline" > /sys/block/mmcblk0/queue/scheduler
    	echo "deadline" > /sys/block/sda/queue/scheduler
else
	echo "cfq" > /sys/block/mmcblk0/queue/scheduler
    	echo "cfq" > /sys/block/sda/queue/scheduler
fi

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
# faster I/O (dorimanx)

for i in /sys/block/*/queue; do
	echo "2" > $i/rq_affinity
	echo "I/O tuned successful." >> $LOG
done

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

