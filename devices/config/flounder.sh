nhb_flounder_lollipop(){
	if [[ -d $maindir/kernel/devices/lollipop/flounder ]]; then
		echo "Copying kernel to rootfs"
		cp -rf $maindir/kernel/devices/lollipop/flounder $workingdir/kernel
	else
		echo "Downloading Kernel and copying to rootfs"
		git clone https://github.com/binkybear/flounder.git -b android-tegra-flounder-3.10-lollipop-release $maindir/kernel/devices/lollipop/flounder
		cp -rf $maindir/kernel/devices/lollipop/flounder $workingdir/kernel
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
