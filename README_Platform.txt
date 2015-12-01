How to build Mobule for Platform
- It is only for modules are needed to using Android build system.
- Please check its own install information under its folder for other module.

[Step to build]
1. Get android open source.
    : version info - Android 5.1.1
    ( Download site : http://source.android.com )

2. Copy module that you want to build - to original android open source
   If same module exist in android open source, you should replace it. (no overwrite)
   
  # It is possible to build all modules at once.
  
3. You should add module name to 'PRODUCT_PACKAGES' in 'build\target\product\core.mk' as following case.
	case 1) ProfessionalAudio : should add 'libjackshm','libjackserver','libjack','androidshmservice','jackd','jack_dummy','jack_alsa','jack_opensles','jack_loopback',
                              'in','out','jack_connect','jack_disconnect','jack_lsp','jack_showtime','jack_simple_client','jack_transport','libasound','libglib-2.0',
                              'libgthread-2.0','libfluidsynth' to PRODUCT_PACKAGES
  case 2) strongSwan : should add 'charon','libcharon','libhydra','libstrongswan' to PRODUCT_PACKAGES
  case 3) e2fsprog : should add 'e2fsck','resize2fs' to PRODUCT_PACKAGES
	case 4) libexifa : should add 'libexifa' to PRODUCT_PACKAGES
	case 5) libjpega : should add 'libjpega' to PRODUCT_PACKAGES
	case 6) KeyUtils : should add 'libkeyutils' to PRODUCT_PACKAGES

ex.) [build\target\product\core.mk] - add all module name for case 1 ~ 8 at once
# ProfessionalAudio
PRODUCT_PACKAGES += \
    libjackshm \
    libjackserver \
    libjack \
    libjacklogger \
    androidshmservice \
    jackd \
    jack_dummy \
    jack_alsa \
    jack_opensles \
    jack_loopback \
    in \
    out \
    jack_connect \
    jack_disconnect \
    jack_lsp \
    jack_showtime \
    jack_simple_client \
    jack_transport \
    libasound \
    libglib-2.0 \
    libgthread-2.0 \
    libfluidsynth
    
# strongSwan
PRODUCT_PACKAGES += \
    charon \
    libcharon \
    libhydra \
    libstrongswan
    
# e2fsprog
PRODUCT_PACKAGES += \
    e2fsck \
    resize2fs
    
# libexifa
PRODUCT_PACKAGES += \
    libexifa
    
# libjpega
PRODUCT_PACKAGES += \
    libjpega
    
# KeyUtils
PRODUCT_PACKAGES += \
    libkeyutils
   
4. excute build command
   ./build_64bit.sh user

Note : 
 You can download the Sbrowser source code from the site below: http://opensource.samsung.com
