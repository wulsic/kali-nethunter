#!/bin/bash
set -e

nhb_kernel_build_setup(){
  export columns=$(tput cols)
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  echo -e -n "\e[31m###\e[0m  SETTING UP  "; for ((n=0;n<($columns-17);n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo

  echo -e "\e[32mBeginning build of \e[33m$androidversion\e[32m kernel for \e[33m$device\e[32m."

  if [[ $device == "flounder" ]]; then
    echo -e "\e[32mChecking for 64-bit Android Toolchain.\e[0m"
    if [[ -d $maindir/files/toolchains/aarch64-linux-android-4.9 ]]; then
      echo -e "\e[32mCopying toolchain to rootfs.\e[0m"
      cp -rf $maindir/files/toolchains/aarch64-linux-android-4.9 $workingdir/toolchain
    else
      echo -e "\e[32mDownloading 64-bit Android Toolchian.\e[0m"
      git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b lollipop-release $maindir/files/toolchains/aarch64-linux-android-4.9
      echo -e "\e[32mCopying toolchain to rootfs.\e[0m"
      cp -rf $maindir/files/toolchains/aarch64-linux-android-4.9 $workingdir/toolchain
    fi
    echo -e "\e[32mSetting export paths.\e[0m"
    # Set path for Kernel building
    export ARCH=arm64
    echo -e "\e[32mARCH=\e[33m$ARCH\e[0m"
    export SUBARCH=arm
    echo -e "\e[32mSUBARCH=\e[33m$SUBARCH\e[0m"
    export CROSS_COMPILE=$workingdir/toolchain/bin/aarch64-linux-android-
    echo -e "\e[32mCROSS_COMPILE=\e[33m$CROSS_COMPILE\e[0m"
  else
    echo -e "\e[32mChecking for 32-bit Android Toolchian.\e[0m"
    if [[ -d $maindir/files/toolchains/arm-eabi-4.7 ]]; then
      echo -e "\e[32mCopying toolchain to rootfs.\e[0m"
      cp -rf $maindir/files/toolchains/arm-eabi-4.7 $workingdir/toolchain
    else
      echo -e "\e[32mDownloading 32-bit Android Toolchian.\e[0m"
      git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-eabi-4.7 $maindir/files/toolchains/arm-eabi-4.7
      echo -e "\e[32mCopying toolchain to rootfs.\e[0m"
      cp -rf $maindir/files/toolchains/arm-eabi-4.7 $workingdir/toolchain
    fi

    echo -e "\e[32mSetting export paths.\e[0m"
    # Set path for Kernel building
    export ARCH=arm
    echo -e "\e[32mARCH=\e[33m$ARCH\e[0m"
    export SUBARCH=arm
    echo -e "\e[32mSUBARCH=\e[33m$SUBARCH\e[0m"
    export CROSS_COMPILE=$workingdir/toolchain/bin/arm-eabi-
    echo -e "\e[32mCROSS_COMPILE=\e[33m$CROSS_COMPILE\e[0m"
  fi

  echo -e "\e[32mCopying prebuilt flash folder to working directory.\e[0m"
  cp -rf $maindir/files/flash/ $workingdir/flashkernel
  echo -e "\e[32mMaking module directory.\e[0m"
  mkdir -p $workingdir/flashkernel/system/lib/modules
  echo -e "\e[32mRemoving unneeded folders and files from flashable directory.\e[0m"
  rm -rf $workingdir/flashkernel/data
  rm -rf $workingdir/flashkernel/sdcard
  rm -rf $workingdir/flashkernel/system/app
  rm -rf $workingdir/flashkernel/META-INF/com/google/android/updater-script
}

nhb_kernel_build(){
  export columns=$(tput cols)
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  echo -e -n "\e[31m###\e[0m  BUILDING KERNEL  "; for ((n=0;n<($columns-22);n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo

  make -j $(($(nproc)*2))

  # Detect if module support is enabled in kernel and if so then build/copy.
  if grep -q CONFIG_MODULES=y .config
    then
    echo -e "\e[32mBuilding modules.\e[0m"
    mkdir -p modules
    make modules_install INSTALL_MOD_PATH=$workingdir/kernel/modules
    echo -e "\e[32mCopying Kernel and modules to flashable kernel folder.\e[0m"
    find modules -name "*.ko" -exec cp -t ../flashkernel/system/lib/modules {} +
  else
    echo -e "\e[32mModule support is disabled.\e[0m"
  fi

  # If this is not just a kernel build by itself it will copy modules and kernel to main flash (rootfs+kernel)
  if [ -d "$workingdir/flash/" ]; then
    echo -e "\e[32mDetected exsisting /flash folder, copying kernel and modules.\e[0m"
    if [ -f "$workingdir/kernel/arch/arm/boot/zImage-dtb" ]; then
      cp $workingdir/kernel/arch/arm/boot/zImage-dtb $workingdir/flash/kernel/kernel
      echo -e "\e[32mzImage-dtb found at $workingdir/kernel/arch/arm/boot/zImage-dtb.\e[0m"
    else
      if [ -f "$workingdir/kernel/arch/arm/boot/zImage" ]; then
        cp $workingdir/kernel/arch/arm/boot/zImage $workingdir/flash/kernel/kernel
        echo -e "\e[32mzImage found at $workingdir/kernel/arch/arm/boot/zImage.\e[0m"
      fi
    fi
    cp $workingdir/flashkernel/system/lib/modules/* $workingdir/flash/system/lib/modules
    # Kali rootfs (chroot) looks for modules in a different folder then Android (/system/lib) when using modprobe
    rsync -HPavm --include='*.ko' -f 'hide,! */' $workingdir/kernel/modules/lib/modules $rootfsdir/kali-armhf-base/lib/
  fi

  # Copy kernel to flashable package, prefer zImage-dtb. Image.gz-dtb appears to be for 64bit kernels for now
  if [ -f "$workingdir/kernel/arch/arm/boot/zImage-dtb" ]; then
    cp $workingdir/kernel/arch/arm/boot/zImage-dtb $workingdir/flashkernel/kernel/kernel
    echo -e "\e[32mzImage-dtb found at $workingdir/kernel/arch/arm/boot/zImage-dtb.\e[0m"
  else
    if [ -f "$workingdir/kernel/arch/arm/boot/zImage" ]; then
      cp $workingdir/kernel/arch/arm/boot/zImage $workingdir/flashkernel/kernel/kernel
      echo -e "\e[32mzImage found at $workingdir/kernel/arch/arm/boot/zImage.\e[0m"
    fi
  fi

  cd $workingdir
}

nhb_zip_kernel(){
  export columns=$(tput cols)
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  echo -e -n "\e[31m###\e[0m  CREATING ZIP  "; for ((n=0;n<($columns-19);n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo

  cd $workingdir/flashkernel/
  echo -e "\e[32mDCreating zip file.\e[0m"
  zip -r6 Kernel-$device-$androidversion-$date.zip *
  echo -e "\e[32mMove zip to root of working directory.\e[0m"
  mv Kernel-$device-$androidversion-$date.zip $workingdir
  cd $workingdir
  # Generate sha1sum
  echo -e "\e[32mGenerating sha1sum for \e[33mKernel-$device-$androidversion-$date.zip.\e[0m"
  sha1sum Kernel-$device-$androidversion-$date.zip > $workingdir/Kernel-$device-$androidversion-$date.sha1sum
  sleep 5
}


if [[ $buildtype == "all" ]]||[[ $buildtype == "allkernels" ]]; then
  androidversion="lollipop"
  for device in $(cat $maindir/devices/.lollipopdevices); do
    nhb_kernel_build_setup
    nhb_${device}_${androidversion}
    nhb_zip_kernel
    if [[ $combine == 1 ]]&&[[ $buildtype == "all" ]]; then
      nhb_combine
    else
      nhb_output
    fi
  done
  androidversion="kitkat"
  for device in $(cat $maindir/devices/.kitkatdevices); do
    nhb_kernel_build_setup
    nhb_${device}_${androidversion}
    nhb_zip_kernel
    if [[ $combine == 1 ]]&&[[ $buildtype == "all" ]]; then
      nhb_combine
    else
      nhb_output
    fi
  done
else
  nhb_kernel_build_setup
  nhb_${device}_${androidversion}
  nhb_zip_kernel
fi
