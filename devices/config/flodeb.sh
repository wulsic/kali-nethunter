nhb_flodeb_kitkat(){
	echo "Downloading Android Toolchain"
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

	f_kernel_build_init

	echo "Downloading Kernel"
	cd $workingdir
	if [[ -d $maindir/kernel/devices/flodeb-kitkat ]]; then
		echo "Copying kernel to rootfs"
		cp -rf $maindir/kernel/devices/flodeb-kitkat $workingdir/kernel
	else
		git clone https://github.com/binkybear/kernel_msm.git -b android-msm-flo-3.4-kitkat-mr2 $maindir/kernel/devices/flodeb-kitkat
		cp -rf $maindir/kernel/devices/flodeb-kitkat $workingdir/kernel
	fi
	cd $workingdir/kernel
	make clean
	sleep 10
	make kali_defconfig
	# Attach kernel builder to updater-script
	cp $maindir/devices/updater-scripts/kitkat/flodeb $workingdir/flashkernel/META-INF/com/google/android/updater-script
	# Start kernel build

	f_kernel_build
}

f_flodeb_lollipop(){
	echo "Downloading Android Toolchain"
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

	f_kernel_build_init

	echo "Downloading Kernel"
	cd $workingdir
	if [[ -d $maindir/kernel/devices/flodeb-lollipop ]]; then
		echo "Copying kernel to rootfs"
		cp -rf $maindir/kernel/devices/flodeb-lollipop $workingdir/kernel
	else
		git clone https://github.com/binkybear/kernel_msm.git -b android-msm-flo-3.4-lollipop-release $maindir/kernel/devices/flodeb-lollipop
		cp -rf $maindir/kernel/devices/flodeb-lollipop $workingdir/kernel
	fi
	cd $workingdir/kernel
	chmod +x scripts/*
	make clean
	sleep 10
	make kali_defconfig
	# Attach kernel builder to updater-script
	cp $maindir/devices/updater-scripts/lollipop/flo-deb $workingdir/flashkernel/META-INF/com/google/android/updater-script
	# Start kernel build

	f_kernel_build
}
