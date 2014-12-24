nhb_mako_stock_kitkat(){
	cd ${basedir}
	echo "Downloading Kernel"
	if [[ -d $maindir/kernel/devices/kitkat/mako ]]; then
		echo "Copying kernel to rootfs"
		cp -rf $maindir/kernel/devices/kitkat/mako $workingdir/kernel
	else
		git clone https://github.com/binkybear/kernel_msm.git -b android-msm-mako-3.4-kitkat-mr2 $maindir/kernel/devices/kitkat/mako
		cp -rf $maindir/kernel/devices/kitkat/mako $workingdir/kernel
	fi
	cd $workingdir/kernel
	unzip ramdisk/4.4.4/ramdisk_kitkat.zip -d $workingdir/flashkernel/kernel/
	make clean
	sleep 10
	make kali_defconfig
	#make mako_defconfig #test default defconfig file
	# Attach kernel builder to updater-script
	cp $maindir/devices/updater-scripts/kitkat/mako $workingdir/flashkernel/META-INF/com/google/android/updater-script
	# Start kernel build

	nhb_kernel_build

	cd $workingdir/flashkernel/kernel
	abootimg --create $workingdir/flashkernel/boot.img -f bootimg.cfg -k $workingdir/kernel/arch/arm/boot/zImage -r initrd.img
	cd $workingdir
}
