nhb_bacon_kitkat(){
	nhb_kernel_build_setup

	cd $workingdir
	echo "Checking for existing kernel."
	if [[ -d $maindir/kernel/devices/kitkat/bacon ]]; then
		echo "Copying kernel to rootfs."
		cp -rf $maindir/kernel/devices/kitkat/bacon $workingdir/kernel
	else
		echo "Downloading Kernel."
		git clone https://github.com/binkybear/AK-OnePone.git -b cm-11.0-ak $maindir/kernel/devices/kitkat/bacon
		echo "Copying kernel to rootfs."
		cp -rf $maindir/kernel/devices/kitkat/bacon $woringdir/kernel
	fi
	cd $workingdir/kernel
	chmod +x scripts/* ramdisk/4/mkbootimg ramdisk/4/dtbToolCM
	make clean
	sleep 10
	make kali_defconfig
	# Attach kernel builder to updater-script
	cp $maindir/devices/updater-scripts/kitkat/bacon $workingdir/flashkernel/META-INF/com/google/android/updater-script
	# Start kernel build

	nhb_kernel_build

	# Start boot.img creation
	cd $workingdir/kernel
	echo "Creating dt.img"
	$workingdir/kernel/ramdisk/4/dtbToolCM -2 -o $workingdir/flashkernel/kernel/dt.img -s 2048 -p $workingdir/kernel/scripts/dtc/ $workingdir/kernel/arch/arm/boot/
	sleep 3
	echo "Creating boot.img"
	$workingdir/kernel/ramdisk/4/mkbootimg --kernel arch/arm/boot/zImage --ramdisk ramdisk/4/initrd.img --cmdline "console=ttyHSL0,115200,n8 androidboot.hardware=bacon user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3" --dt ../flashkernel/kernel/dt.img --output ../flashkernel/boot.img
}

nhb_bacon_lollipop(){
	nhb_kernel_build_setup

	cd $workingdir
	echo "Downloading Kernel"
	if [[ -d $maindir/kernel/devices/lollipop/bacon ]]; then
			echo "Copying kernel to rootfs"
			cp -rf $maindir/kernel/devices/lollipop/bacon $workingdir/kernel
	else
			git clone https://github.com/binkybear/furnace-bacon.git -b cm-12.0 $maindir/kernel/devices/lollipop/bacon
		cp -rf $maindir/kernel/devices/lollipop/bacon $workingdir/kernel
	fi
	cd $workingdir/kernel
	chmod +x scripts/* ramdisk/5/mkbootimg ramdisk/5/dtbToolCM
	make clean
	sleep 10
	make kali_defconfig
	# Attach kernel builder to updater-script
	cp $maindir/devices/updater-scripts/lollipop/bacon $workingdir/flashkernel/META-INF/com/google/android/updater-script
	# Start kernel build

	nhb_kernel_build

	# Start boot.img creation
	cd $workingdir/kernel
	echo "Creating dt.img"
	$workingdir/kernel/ramdisk/5/dtbToolCM -2 -o $workingdir/flashkernel/kernel/dt.img -s 2048 -p $workingdir/kernel/scripts/dtc/ $workingdir/kernel/arch/arm/boot/
	sleep 3
	echo "Creating boot.img"
	$workingdir/kernel/ramdisk/5/mkbootimg --kernel arch/arm/boot/zImage --ramdisk ramdisk/5/initrd.img --cmdline "console=ttyHSL0,115200,n8 androidboot.hardware=bacon user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3 androidboot.selinux=permissive" --dt ../flashkernel/kernel/dt.img --output ../flashkernel/boot.img
}
