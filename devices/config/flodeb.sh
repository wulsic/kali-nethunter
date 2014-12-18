nhb_flodeb_kitkat(){
	nhb_kernel_build_setup

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

	nhb_kernel_build
}

nhb_flodeb_lollipop(){
	nhb_kernel_build_setup

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
	cp $maindir/devices/updater-scripts/lollipop/flodeb $workingdir/flashkernel/META-INF/com/google/android/updater-script
	# Start kernel build

	nhb_kernel_build
}
