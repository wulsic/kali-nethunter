#!/bin/bash
set -e


nhb_kernel_build_setup(){
  if [[ $devicearch == "arm64" ]]; then
    echo "Downloading Android Toolchain"
    if [[ -d $maindir/files/toolchains/aarch64-linux-android-4.9 ]]; then
      echo "Copying toolchain to rootfs"
      cp -rf $maindir/files/toolchains/aarch64-linux-android-4.9 $workingdir/toolchain
    else
      git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b lollipop-release $maindir/files/toolchains/aarch64-linux-android-4.9
      cp -rf $maindir/files/toolchains/aarch64-linux-android-4.9 $workingdir/toolchain
    fi

    echo "Setting export paths"
    # Set path for Kernel building
    export ARCH=arm64
    export SUBARCH=arm
    export CROSS_COMPILE=$workingdir/toolchain/bin/aarch64-linux-android-
  else
    echo "Downloading Android Toolchian"
    if [[ -d $maindir/files/toolchains/arm-eabi-4.7 ]]; then
      echo "Copying toolchain to rootfs"
      cp -rf $maindir/files/toolchains/arm-eabi-4.7 $workingdir/toolchain
    else
      git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-eabi-4.7 $maindir/files/toolchains/arm-eabi-4.7
      cp -rf $maindir/files/toolchains/arm-eabi-4.7 $workingdir/toolchain
    fi

    echo "Setting export paths"
    # Set path for Kernel building
    export ARCH=arm
    export SUBARCH=arm
    export CROSS_COMPILE=$workingdir/toolchain/bin/arm-eabi-
  fi
  cp -rf $maindir/files/flash/ $workingdir/flashkernel
  mkdir -p $workingdir/flashkernel/system/lib/modules
  rm -rf $workingdir/flashkernel/data
  rm -rf $workingdir/flashkernel/sdcard
  rm -rf $workingdir/flashkernel/system/app
  rm -rf $workingdir/flashkernel/META-INF/com/google/android/updater-script
}

nhb_kernel_build(){
  echo "Building Kernel"
  make -j $(grep -c processor /proc/cpuinfo)

  # Detect if module support is enabled in kernel and if so then build/copy.
  if grep -q CONFIG_MODULES=y .config
    then
    echo "Building modules"
    mkdir -p modules
    make modules_install INSTALL_MOD_PATH=$workingdir/kernel/modules
    echo "Copying Kernel and modules to flashable kernel folder"
    find modules -name "*.ko" -exec cp -t ../flashkernel/system/lib/modules {} +
  else
    echo "Module support is disabled."
  fi

  # If this is not just a kernel build by itself it will copy modules and kernel to main flash (rootfs+kernel)
  if [ -d "$workingdir/flash/" ]; then
    echo "Detected exsisting /flash folder, copying kernel and modules"
    if [ -f "$workingdir/kernel/arch/arm/boot/zImage-dtb" ]; then
      cp $workingdir/kernel/arch/arm/boot/zImage-dtb $workingdir/flash/kernel/kernel
      echo "zImage-dtb found at $workingdir/kernel/arch/arm/boot/zImage-dtb"
    else
      if [ -f "$workingdir/kernel/arch/arm/boot/zImage" ]; then
        cp $workingdir/kernel/arch/arm/boot/zImage $workingdir/flash/kernel/kernel
        echo "zImage found at $workingdir/kernel/arch/arm/boot/zImage"
      fi
    fi
    cp $workingdir/flashkernel/system/lib/modules/* $workingdir/flash/system/lib/modules
    # Kali rootfs (chroot) looks for modules in a different folder then Android (/system/lib) when using modprobe
    rsync -HPavm --include='*.ko' -f 'hide,! */' $workingdir/kernel/modules/lib/modules $rootfsdir/kali-armhf/lib/
  fi

  # Copy kernel to flashable package, prefer zImage-dtb. Image.gz-dtb appears to be for 64bit kernels for now
  if [ -f "$workingdir/kernel/arch/arm/boot/zImage-dtb" ]; then
    cp $workingdir/kernel/arch/arm/boot/zImage-dtb $workingdir/flashkernel/kernel/kernel
    echo "zImage-dtb found at $workingdir/kernel/arch/arm/boot/zImage-dtb"
  else
    if [ -f "$workingdir/kernel/arch/arm/boot/zImage" ]; then
      cp $workingdir/kernel/arch/arm/boot/zImage $workingdir/flashkernel/kernel/kernel
      echo "zImage found at $workingdir/kernel/arch/arm/boot/zImage"
    fi
  fi

  cd $workingdir

  #Adding Kernel build
  # 1. Will check if kernel was added to main flashable zip (one with rootfs).  If yes it will skip.
  # 2. If it detects KERNEL_SCRIPT_START it will not add it to flashable zip (rootfs)
  # 3. If the updater-script is not found it will assume this is a kernel only build so it will not try to add it

  if [ -f "$workingdir/flash/META-INF/com/google/android/updater-script" ]; then
    if grep -Fxq "#KERNEL_SCRIPT_START" "$workingdir/flash/META-INF/com/google/android/updater-script"
      then
      echo "Kernel already added to main updater-script"
    else
      echo "Adding Kernel install to updater-script in main update.zip"
      cat $workingdir/flashkernel/META-INF/com/google/android/updater-script >> $workingdir/flash/META-INF/com/google/android/updater-script
    fi
  fi
}

nhb_zip_kernel(){
  apt-get install -y zip
  cd $workingdir/flashkernel/
  zip -r6 Kernel-$device-$androidversion-$date.zip *
  mv Kernel-$device-$androidversion-$date.zip $workingdir
  cd $workingdir
  # Generate sha1sum
  echo "Generating sha1sum for Kernel-$device-$androidversion-$date.zip"
  sha1sum Kernel-$device-$androidversion-$date.zip > $workingdir/Kernel-$device-$androidversion-$date.sha1sum
  sleep 5
}


if [[ $buildtype == "all" ]]; then
  androidversion="lollipop"
  for device in bacon flodeb flounder hammerhead manta shamu; do
    nhb_${device}_${androidversion}
    nhb_zip_kernel
    nhb_output
  done
  androidversion="kitkat"
  for device in bacon flodeb groupertilapia hammerhead mako manta; do
    nhb_${device}_${androidversion}
    nhb_zip_kernel
    nhb_output
    echo "Building for $androidversion on $device"
  done
else
  nhb_${device}_${androidversion}
  nhb_zip_kernel
fi
