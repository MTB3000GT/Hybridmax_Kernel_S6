################################################################################

1. How to Build
	- get Toolchain
		From android git server , codesourcery and etc ..
		 - arm-eabi-4.8
		
	- edit Makefile
		edit "CROSS_COMPILE" to right toolchain path(You downloaded).
		  EX)  CROSS_COMPILE= $(android platform directory you download)/android/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi-
		  Ex)  CROSS_COMPILE=/usr/local/toolchain/aarch64-linux-android-4.8/bin/aarch64-linux-android-		// check the location of toolchain
  	
        - to Build
          $ make ARCH=arm64 exynos7420-zeroflte_defconfig
          $ make ARCH=arm64

2. Output files
	- Kernel : arch\arm64\boot\Image
	- module : drivers/*/*.ko

3. How to Clean	
		$ make clean
################################################################################
