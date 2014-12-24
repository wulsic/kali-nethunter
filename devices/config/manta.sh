nhb_manta_kitkat(){
	echo "Downloading Kernel"
	if [[ -d $maindir/kernel/devices/kitkat/manta ]]; then
		echo "Copying kernel to rootfs"
		cp -rf $maindir/kernel/devices/kitkat/manta $workingdir/kernel
	else
		git clone https://github.com/binkybear/kernel_samsung_manta.git -b thunderkat $maindir/kernel/devices/kitkat/manta
		cp -rf $maindir/kernel/devices/kitkat/manta $workingdir/kernel
	fi
	cd $workingdir/kernel
	make clean
	sleep 10
	make kali_defconfig
	# Attach kernel builder to updater-script
	cp $maindir/devices/updater-scripts/kitkat/manta $workingdir/flashkernel/META-INF/com/google/android/updater-script

	nhb_kernel_build
}

nhb_manta_lollipop(){
	echo "Downloading Kernel"
	if [[ -d $maindir/kernel/devices/lollipop/manta ]]; then
  	echo "Copying kernel to rootfs"
  	cp -rf $maindir/kernel/devices/lollipop/manta $workingdir/kernel
	else
  	git clone https://github.com/binkybear/nexus10-5.git -b android-exynos-manta-3.4-lollipop-release $maindir/kernel/devices/lollipop/manta
		cp -rf $maindir/kernel/devices/lollipop/manta $workingdir/kernel
	fi
	cd $workingdir/kernel
	make clean
	sleep 10
	make kali_defconfig
	# Attach kernel builder to updater-script
	cp $maindir/devices/updater-scripts/lollipop/manta $workingdir/flashkernel/META-INF/com/google/android/updater-script

	nhb_kernel_build
}
