#!/bin/bash

clear

#
# VAR
#
PARAM=$1
DATE_START=$(date +"%s")
CWM_MOVE="/home/anarkia1976/Desktop/"
TOOLCHAIN_LINARO="${HOME}/android/AK-linaro/4.7.3-2013.04.20130415/bin/arm-linux-gnueabihf-"
TOOLCHAIN_GOOGLE="${HOME}/android/AK-linaro/4.6.x-google/bin/arm-eabi-"
TOOLCHAIN_STRIP="${HOME}/android/AK-linaro/4.7.3-2013.04.20130415/bin/arm-linux-gnueabihf-strip"

if [ "${PARAM}" == "debug" ]; then
 echo ""; echo "# AK BUILD DEBUG ------------------------------------------------------------------------------------------------"; echo ""
  #
  # CREATE DEFAULT CONFIG
  #
  make clean; sleep 3; make distclean; sleep 3
   echo ""
  rm -rfv .config; rm -rfv .config.old
   echo ""
  make CROSS_COMPILE=$TOOLCHAIN_GOOGLE ARCH=arm tuna_ak_debug_defconfig
  #make CROSS_COMPILE=$TOOLCHAIN_LINARO ARCH=arm tuna_ak_debug_defconfig

  #
  # LOCAL KERNEL VERSION
  #
  ak_ver="AK.666.DEBUG"; export LOCALVERSION="~"`echo $ak_ver`

  debug=1

else
 echo ""; echo "# AK BUILD FULL ------------------------------------------------------------------------------------------------"; echo ""
  #
  # CREATE DEFAULT CONFIG
  #
  make clean; sleep 3; make distclean; sleep 3
   echo ""
  rm -rfv .config; rm -rfv .config.old
   echo ""
  #make CROSS_COMPILE=$TOOLCHAIN_GOOGLE ARCH=arm tuna_ak_defconfig
  make CROSS_COMPILE=$TOOLCHAIN_LINARO ARCH=arm tuna_ak_defconfig

  #
  # LOCAL KERNEL VERSION
  #
  ak_ver="AK.300.SKL"; export LOCALVERSION="~"`echo $ak_ver`

  debug=0

fi

#
# CROSS COMPILE KERNEL MODULES
#
#make CROSS_COMPILE=$TOOLCHAIN_GOOGLE ARCH=arm -j4 modules
make CROSS_COMPILE=$TOOLCHAIN_LINARO ARCH=arm -j4 modules

#
# FIND .KO MODULE CREATE WITH CROSS COMPILE
# AND THEN COPY .KO MODULE TO CWM SCRIPT
#
echo ""
rm -rfv ${HOME}/android/AK-ramdisk/cwm/system/lib/modules/*
find ${HOME}/android/AK-tuna/ -name '*.ko' -exec cp -v {} ${HOME}/android/AK-ramdisk/cwm/system/lib/modules \;
$TOOLCHAIN_STRIP --strip-debug ${HOME}/android/AK-ramdisk/cwm/system/lib/modules/*.ko
echo ""

#
# CROSS COMPILE KERNEL WITH TOOLCHAIN
#
#make CROSS_COMPILE=$TOOLCHAIN_GOOGLE ARCH=arm -j4 zImage
make CROSS_COMPILE=$TOOLCHAIN_LINARO ARCH=arm -j4 zImage

#
# COPY ZIMAGE OF KERNEL
# FOR MERGE WITH RAMDISK
#
cp -vr arch/arm/boot/zImage ../AK-ramdisk/
cd ../AK-ramdisk/ramdisk-4.2/
chmod 750 init* charger
chmod 644 default.prop
chmod 640 fstab.tuna
chmod 644 ueventd*
cd ..
./repack-bootimg.pl zImage ramdisk-4.2/ boot.img
cp -vr boot.img cwm/

#
# CREATE A CWM PKG
# FOR FLASH FROM RECOVERY
#
cd cwm
zip -r `echo $ak_ver`.zip *
rm -rf $CWM_MOVE/`echo $ak_ver`.zip
cp -vr `echo $ak_ver`.zip $CWM_MOVE/AK-Kernel/
if [ ! -d ../zip ]; then
 mkdir ../zip
fi
mv `echo $ak_ver`.zip ../zip/
rm -rf `echo $ak_ver`.zip boot.img
cd ..
cd ../AK-tuna/

echo .
echo ..
echo ... Compile Complite ! ... `echo $ak_ver`.zip
echo ..
echo .

#
# PRINT BUILDING COMPILE-TIME
#
echo ""
DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo ""
