nhb_hammerhead_kitkat(){
	nhb_kernel_build_setup

	cd $workingdir
	echo "Downloading Kernel"
	if [[ -d $maindir/devices/kernels/kitkat/hammerhead ]]; then
		echo "Copying kernel to rootfs"
		cp -rf $maindir/devices/kernels/kitkat/hammerhead $workingdir/kernel
	else
		git clone https://github.com/binkybear/furnace_kernel_lge_hammerhead.git -b android-4.4 $maindir/devices/kernels/kitkat/hammerhead
		cp -rf $maindir/devices/kernels/kitkat/hammerhead $workingdir/kernel
	fi
	cd $workingdir/kernel
	make clean
	sleep 10
	make kali_defconfig
	# Attach kernel builder to updater-script
	cp $maindir/devices/updater-scripts/kitkat/hammerhead $workingdir/flashkernel/META-INF/com/google/android/updater-script
	# Start kernel build

	nhb_kernel_build
}

nhb_hammerhead_lollipop(){
		nhb_kernel_build_setup

		cd $workingdir
		echo "Downloading Kernel"
		if [[ -d $maindir/kernel/devices/lollipop/hammerhead ]]; then
  		echo "Copying kernel to rootfs"
  		cp -rf $maindir/kernel/devices/lollipop/hammerhead $workingdir/kernel
		else
  		git clone https://github.com/binkybear/kernel_msm.git -b android-msm-hammerhead-3.4-lollipop-release $maindir/kernel/devices/lollipop/hammerhead
			cp -rf $maindir/kernel/devices/lollipop/hammerhead $workingdir/kernel
		fi
		cd $workingdir/kernel
		chmod +x scripts/*
		make clean
		sleep 10
		make kali_defconfig
		# Attach kernel builder to updater-script
		cp $maindir/devices/updater-scripts/lollipop/hammerhead $workingdir/flashkernel/META-INF/com/google/android/updater-script

		nhb_kernel_build

		cd $workingdir/flashkernel/kernel
		abootimg --create $workingdir/flashkernel/boot.img -f $workingdir/kernel/ramdisk/5/bootimg.cfg -k $workingdir/kernel/arch/arm/boot/zImage-dtb -r $workingdir/kernel/ramdisk/5/initrd.img
		cd $workingdir
		if [ -d "$workingdir/flash/" ]; then
			cp $workingdir/flashkernel/boot.img $workingdir/flash/boot.img
		fi
}
