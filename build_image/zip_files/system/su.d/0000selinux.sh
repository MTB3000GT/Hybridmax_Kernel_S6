BB=/system/xbin/busybox

mount -o rw,remount / 2>/dev/null
mount -o rw,remount / / 2>/dev/null
mount -o rw,remount rootfs 2>/dev/null
mount -o rw,remount /system 2>/dev/null
mount -o rw,remount /system /system 2>/dev/null
$BB mount -o rw,remount / 2>/dev/null
$BB mount -o rw,remount / / 2>/dev/null
$BB mount -o rw,remount rootfs 2>/dev/null
$BB mount -o rw,remount /system 2>/dev/null
$BB mount -o rw,remount /system /system 2>/dev/null

/system/xbin/daemonsu --auto-daemon &

setenforce 0
$BB echo "0" > /sys/fs/selinux/enforce
