nhb_groupertilapia_kitkat(){
	echo -e "\e[32mChecking for existing kernel.\e[0m"
	if [[ -d $maindir/kernel/devices/kitkat/groupertilapia ]]; then
		echo -e "\e[32mKernel found.\e[0m"
		echo -e "\e[32mCopying kernel to rootfs.\e[0m"
		cp -rf $maindir/kernel/devices/kitkat/groupertilapia $workingdir/kernel
	else
		echo -e "\e[32mKernel not found.\e[0m"
		echo -e "\e[32mDownloading Kernel.\e[0m"
		git clone https://github.com/binkybear/kangaroo.git -b kangaroo $maindir/kernel/devices/kitkat/groupertilapia
		echo -e "\e[32mCopying kernel to rootfs.\e[0m"
		cp -rf $maindir/kernel/devices/kitkat/groupertilapia $workingdir/kernel
	fi
	cd $workingdir/kernel
	echo -e "\e[32mRunning 'make clean'.\e[0m"
	make clean
	sleep 3
	echo -e "\e[32mMaking kali_defconfig.\e[0m"
	make kali_defconfig
	# Attach kernel builder to updater-script
	echo -e "\e[32mCopying updater script to working directory.\e[0m"
	cp $maindir/devices/updater-scripts/kitkat/groupertilapia $workingdir/flashkernel/META-INF/com/google/android/updater-script

	nhb_kernel_build
}
