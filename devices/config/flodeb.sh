nhb_flodeb_kitkat(){
	echo -e "\e[32mChecking for existing kernel.\e[0m"
	if [[ -d $maindir/kernel/devices/kitkat/flodeb ]]; then
		echo -e "\e[32mKernel found.\e[0m"
		echo -e "\e[32mCopying kernel to rootfs.\e[0m"
		cp -rf $maindir/kernel/devices/kitkat/flodeb $workingdir/kernel
	else
		echo -e "\e[32mKernel not found.\e[0m"
		echo -e "\e[32mDownloading kernel.\e[0m"
		git clone https://github.com/binkybear/kernel_msm.git -b android-msm-flo-3.4-kitkat-mr2 $maindir/kernel/devices/kitkat/flodeb
		echo -e "\e[32mCopying kernel to rootfs.\e[0m"
		cp -rf $maindir/kernel/devices/kitkat/flodeb $workingdir/kernel
	fi
	cd $workingdir/kernel
	echo -e "\e[32mRunning 'make clean'.\e[0m"
	make clean
	sleep 10
	echo -e "\e[32mMaking kali_defconfig.\e[0m"
	make kali_defconfig
	# Attach kernel builder to updater-script
	echo -e "\e[32mCopying updater script to working directory.\e[0m"
	cp $maindir/devices/updater-scripts/kitkat/flodeb $workingdir/flashkernel/META-INF/com/google/android/updater-script
	# Start kernel build

	nhb_kernel_build
}

nhb_flodeb_lollipop(){
	echo -e "\e[32mChecking for existing kernel.\e[0m"
	if [[ -d $maindir/kernel/devices/lollipop/flodeb ]]; then
		echo -e "\e[32mKernel found.\e[0m"
		echo -e "\e[32mCopying kernel to rootfs.\e[0m"
		cp -rf $maindir/kernel/devices/lollipop/flodeb $workingdir/kernel
	else
		echo -e "\e[32mKernel not found.\e[0m"
		echo -e "\e[32mDownloading kernel.\e[0m"
		git clone https://github.com/binkybear/kernel_msm.git -b android-msm-flo-3.4-lollipop-release $maindir/kernel/devices/lollipop/flodeb
		echo -e "\e[32mCopying kernel to rootfs.\e[0m"
		cp -rf $maindir/kernel/devices/lollipop/flodeb $workingdir/kernel
	fi
	cd $workingdir/kernel
	echo -e "\e[32mMaking scripts executable.\e[0m"
	chmod +x scripts/*
	echo -e "\e[32mrunning 'make clean'.\e[0m"
	make clean
	sleep 10
	echo -e "\e[32mMaking kali_defconfig.\e[0m"
	make kali_defconfig
	# Attach kernel builder to updater-script
	echo -e "\e[32mCopying updater script to working directory.\e[0m"
	cp $maindir/devices/updater-scripts/lollipop/flodeb $workingdir/flashkernel/META-INF/com/google/android/updater-script
	# Start kernel build

	nhb_kernel_build
}
