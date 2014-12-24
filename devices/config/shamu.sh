nhb_shamu_lollipop(){
	cd $workingdir
	echo "Downloading Kernel"
	if [[ -d $maindir/kernel/devices/lollipop/shamu ]]; then
		echo "Copying kernel to rootfs"
		cp -rf $maindir/kernel/devices/lollipop/shamu $workingdir/kernel
	else
		git clone https://github.com/binkybear/kernel_msm.git -b android-msm-shamu-3.10-lollipop-release $maindir/kernel/devices/lollipop/shamu
		cp -rf $maindir/kernel/devices/lollipop/shamu $workingdir/kernel
	fi
	cd $workingdir/kernel
	chmod +x scripts/*
	make clean
	sleep 10
	make kali_defconfig
	# Attach kernel builder to updater-script
	cp $maindir/devices/updater-scripts/lollipop/shamu $workingdir/flashkernel/META-INF/com/google/android/updater-script

	nhb_kernel_build

	cd $workingdir/flashkernel/kernel
	abootimg --create $workingdir/flashkernel/boot.img -f $workingdir/kernel/ramdisk/5/bootimg.cfg -k $workingdir/kernel/arch/arm/boot/zImage-dtb -r $workingdir/kernel/ramdisk/5/initrd.img
	cd $workingdir
}
