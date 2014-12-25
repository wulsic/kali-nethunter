nhb_manta_kitkat(){
	echo -e "\e[32mChecking for existing kernel.\e[0m"
	if [[ -d $maindir/kernel/devices/kitkat/manta ]]; then
		echo -e "\e[32mKernel found.\e[0m"
		echo -e "\e[32mCopying kernel to rootfs.\e[0m"
		cp -rf $maindir/kernel/devices/kitkat/manta $workingdir/kernel
	else
		echo -e "\e[32mKernel not found.\e[0m"
		echo -e "\e[32mDownloading Kernel.\e[0m"
		git clone https://github.com/binkybear/kernel_samsung_manta.git -b thunderkat $maindir/kernel/devices/kitkat/manta
		echo -e "\e[32mCopying kernel to rootfs.\e[0m"
		cp -rf $maindir/kernel/devices/kitkat/manta $workingdir/kernel
	fi
	cd $workingdir/kernel
	echo -e "\e[32mRunning 'make clean'.\e[0m"
	make clean
	sleep 10
	echo -e "\e[32mMaking kali_defconfig.\e[0m"
	make kali_defconfig
	# Attach kernel builder to updater-script
	echo -e "\e[32mCopying updater script to working directory.\e[0m"
	cp $maindir/devices/updater-scripts/kitkat/manta $workingdir/flashkernel/META-INF/com/google/android/updater-script

	nhb_kernel_build
}

nhb_manta_lollipop(){
	echo -e "\e[32mChecking for existing kernel.\e[0m"
	if [[ -d $maindir/kernel/devices/lollipop/manta ]]; then
		echo -e "\e[32mKernel found.\e[0m"
		echo -e "\e[32mCopying kernel to rootfs.\e[0m"
  	cp -rf $maindir/kernel/devices/lollipop/manta $workingdir/kernel
	else
		echo -e "\e[32mKernel not found.\e[0m"
		echo -e "\e[32mDownloading Kernel.\e[0m"
		git clone https://github.com/binkybear/nexus10-5.git -b android-exynos-manta-3.4-lollipop-release $maindir/kernel/devices/lollipop/manta
		echo -e "\e[32mCopying kernel to rootfs.\e[0m"
		cp -rf $maindir/kernel/devices/lollipop/manta $workingdir/kernel
	fi
	cd $workingdir/kernel
	echo -e "\e[32mRunning 'make clean'.\e[0m"
	make clean
	sleep 10
	echo -e "\e[32mMaking kali_defconfig.\e[0m"
	make kali_defconfig
	# Attach kernel builder to updater-script
	echo -e "\e[32mCopying updater script to working directory.\e[0m"
	cp $maindir/devices/updater-scripts/lollipop/manta $workingdir/flashkernel/META-INF/com/google/android/updater-script

	nhb_kernel_build
}
