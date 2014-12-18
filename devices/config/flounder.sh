nhb_nexus9_lollipop(){
	echo "Downloading Android Toolchain"
	if [[ -d $maindir/files/toolchains/toolchain64 ]]; then
		echo "Copying toolchain to rootfs"
		cp -rf $maindir/files/toolchains/toolchain64 $workingdir/toolchain64
	else
		git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b lollipop-release $maindir/toolchains/toolchain64
		cp -rf $maindir/files/toolchains/toolchain64 $workingdir/toolchain64
	fi

	echo "Setting export paths"
	# Set path for Kernel building
	export ARCH=arm64
	export SUBARCH=arm
	export CROSS_COMPILE=$workingdir/toolchain64/bin/aarch64-linux-android-

	nhb_kernel_build_init

	if [[ -d $maindir/kernel/devices/flounder-lollipop ]]; then
  	echo "Copying kernel to rootfs"
  	cp -rf $maindir/kernel/devices/flounder-lollipop $workingdir/kernel
	else
		echo "Downloading Kernel and copying to rootfs"
		git clone https://github.com/binkybear/flounder.git -b android-tegra-flounder-3.10-lollipop-release $maindir/kernel/devices/flounder-lollipop
		cp -rf $maindir/kernel/devices/flounder-lollipop $workingdir/kernel
	fi
	cd $workingdir/kernel
	chmod +x scripts/*
	chmod +x arch/arm64/kernel/vdso/*.sh
	make clean
	sleep 10

	make kali_defconfig

	# Attach kernel builder to updater-script
	cp $maindir/devices/updater-scripts/lollipop/flounder $workingdir/flashkernel/META-INF/com/google/android/updater-script
	nhb_kernel_build
	cd $workingdir/flashkernel/kernel
	abootimg --create $workingdir/flashkernel/boot.img -f $workingdir/kernel/ramdisk/5/bootimg.cfg -k $workingdir/kernel/arch/arm64/boot/Image.gz-dtb -r $workingdir/kernel/ramdisk/5/initrd.img
	cd $workingdir
	if [ -d "${basedir}/flash/" ]; then
		cp $workingdir/flashkernel/boot.img $workingdir/flash/boot.img
	fi

	nhb_zip_kernel
}
