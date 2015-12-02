#!/bin/bash
# Kernel Build Script by Hybridmax

# vars
export KERNEL_DIR=$(pwd)
export BUILD_USER="$USER"
export TOOLCHAIN_DIR=/home/$BUILD_USER/android/toolchains/arm64
export CPU_JOB_NUM=$(grep processor /proc/cpuinfo | awk '{field=$NF};END{print field+1}')
export IMG=arch/arm64/boot
export BUILD_IMG=build_image
export KERNEL_DEFCONFIG=hybridmax_defconfig
export DEVELOPER="Hybridmax"
export DEVICE="S6"
export VERSION_NUMBER="Alpha-1"
export KERNELNAME="$DEVELOPER-$DEVICE-$VERSION_NUMBER"
export HYBRIDVER="-$KERNELNAME"

#########################################################################################
# Toolchains

# Linaro
#BCC=$TOOLCHAIN_DIR/linaro_aarch64_5.2.1/bin/aarch64-linux-android-

# Uber
#BCC=$TOOLCHAIN_DIR/uber_aarch64_5.2/bin/aarch64-linux-android-
BCC=$TOOLCHAIN_DIR/uber_aarch64_6.0/bin/aarch64-linux-android-

#########################################################################################
# Cleanup

CLEANUP()
{
        clear
        echo "***********************************"
        echo "Cleaning Up..."
        echo "***********************************"
        echo
        sleep 3
        make mrproper
        ccache -c
        rm -rf arch/arm64/boot/Image*.*
        rm -rf arch/arm64/boot/.Image*.*
	rm -f arch/arm/boot/*.dtb
	rm -f arch/arm/boot/*.cmd
}

#########################################################################################
# Build Kernel

BUILD_KERNEL()
{
        echo "***********************************"
        echo "Starting Build..."
        echo "***********************************"
        echo
        sleep 3

# build_vars
        export ARCH=arm64
        export SUBARCH=arm64
#       export USE_CCACHE=1
#       export USE_SEC_FIPS_MODE=true
#       export KCONFIG_NOTIMESTAMP=true
        export CROSS_COMPILE=$BCC
#       export ENABLE_GRAPHITE=true
        make ARCH=arm64 $KERNEL_DEFCONFIG
        sed -i 's,CONFIG_LOCALVERSION="-Hybridmax",CONFIG_LOCALVERSION="'$HYBRIDVER'",' .config
        make ARCH=arm64 -j$CPU_JOB_NUM

# Image Check

if [ -f "arch/arm64/boot/Image" ]; then
        clear
        echo "***********************************"
	echo "Done, Compilation was successfull!"
        echo "***********************************"
	cp $IMG/Image $BUILD_IMG/boot/Image
else
	clear
        echo "***********************************"
	echo "Compilation failed!"
        echo "Please check build.log"
        echo "***********************************"
	echo
        sleep 3
fi
}

CLEANUP;

#########################################################################################
# Create Log File

rm -rf ./build.log
(
	START_TIME=`date +%s`
	BUILD_DATE=`date +%m-%d-%Y`
	BUILD_KERNEL


	END_TIME=`date +%s`
	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "Total compile time is $ELAPSED_TIME seconds"
) 2>&1	 | tee -a ./build.log
