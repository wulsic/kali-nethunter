nhb_groupertilapia_kitkat(){
	echo "Downloading Kernel"
	# Kangaroo Kernel has y-cable support and kexec patch built in
	if [[ -d $maindir/kernel/devices/kitkat/groupertilapia ]]; then
		echo "Copying kernel to rootfs"
		cp -rf $maindir/kernel/devices/kitkat/groupertilapia $workingdir/kernel
	else
		git clone https://github.com/binkybear/kangaroo.git -b kangaroo $maindir/kernel/devices/kitkat/groupertilapia
		cp -rf $maindir/kernel/devices/kitkat/groupertilapia $workingdir/kernel
	fi
	cd $workingdir/kernel
	make clean
	sleep 3
	make kali_defconfig
	# Attach kernel builder to updater-script
	cp $maindir/devices/updater-scripts/kitkat/groupertilapia $workingdir/flashkernel/META-INF/com/google/android/updater-script

	nhb_kernel_build
}
