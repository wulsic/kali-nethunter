nhb_flounder_lollipop(){
	echo -e "\e[32mChecking for kernel.\e[0m"
	if [[ -d $maindir/kernel/devices/lollipop/flounder ]]; then
		echo -e "\e[32mCopying updater script to working directory.\e[0m"
		echo -e "\e[32mCopying kernel to rootfs.\e[0m"
		cp -rf $maindir/kernel/devices/lollipop/flounder $workingdir/kernel
	else
		echo -e "\e[32mCopying updater script to working directory.\e[0m"
		echo -e "\e[32mDownloading Kernel and copying to rootfs.\e[0m"
		git clone https://github.com/binkybear/flounder.git -b android-tegra-flounder-3.10-lollipop-release $maindir/kernel/devices/lollipop/flounder
		echo -e "\e[32mCopying updater script to working directory.\e[0m"
		cp -rf $maindir/kernel/devices/lollipop/flounder $workingdir/kernel
	fi
	cd $workingdir/kernel
	echo -e "\e[32mMaking files executable.\e[0m"
	chmod +x scripts/*
	chmod +x arch/arm64/kernel/vdso/*.sh
	echo -e "\e[32mRunning 'make clean'.\e[0m"
	make clean
	sleep 10
	echo -e "\e[32mMaking kali_defconfig.\e[0m"
	make kali_defconfig
	# Attach kernel builder to updater-script
	echo -e "\e[32mCopying updater script to working directory.\e[0m"
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
