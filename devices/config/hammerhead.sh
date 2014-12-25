nhb_hammerhead_kitkat(){
	echo -e "\e[32mChecking for existing kernel.\e[0m"
	if [[ -d $maindir/devices/kernels/kitkat/hammerhead ]]; then
		echo -e "\e[32mKernel found.\e[0m"
		echo -e "\e[32mCopying kernel to rootfs.\e[0m"
		cp -rf $maindir/devices/kernels/kitkat/hammerhead $workingdir/kernel
	else
		echo -e "\e[32mKernel not found.\e[0m"
		echo -e "\e[32mDownloading Kernel.\e[0m"
		git clone https://github.com/binkybear/furnace_kernel_lge_hammerhead.git -b android-4.4 $maindir/devices/kernels/kitkat/hammerhead
		echo -e "\e[32mCopying kernel to rootfs.\e[0m"
		cp -rf $maindir/devices/kernels/kitkat/hammerhead $workingdir/kernel
	fi
	cd $workingdir/kernel
	echo -e "\e[32mRunning 'make clean'.\e[0m"
	make clean
	sleep 10
	echo -e "\e[32mMaking kali_defconfig.\e[0m"
	make kali_defconfig
	# Attach kernel builder to updater-script
	echo -e "\e[32mCopying updater script to working directory.\e[0m"
	cp $maindir/devices/updater-scripts/kitkat/hammerhead $workingdir/flashkernel/META-INF/com/google/android/updater-script
	# Start kernel build

	nhb_kernel_build
}

nhb_hammerhead_lollipop(){
	echo -e "\e[32mChecking for existing kernel.\e[0m"
		if [[ -d $maindir/kernel/devices/lollipop/hammerhead ]]; then
			echo -e "\e[32mKernel found.\e[0m"
			echo -e "\e[32mCopying kernel to rootfs.\e[0m"
  		cp -rf $maindir/kernel/devices/lollipop/hammerhead $workingdir/kernel
		else
			echo -e "\e[32mKernel not found.\e[0m"
			echo -e "\e[32mDownloading Kernel.\e[0m"
			git clone https://github.com/binkybear/kernel_msm.git -b android-msm-hammerhead-3.4-lollipop-release $maindir/kernel/devices/lollipop/hammerhead
			echo -e "\e[32mCopying kernel to rootfs.\e[0m"
			cp -rf $maindir/kernel/devices/lollipop/hammerhead $workingdir/kernel
		fi
		cd $workingdir/kernel
		echo -e "\e[32mMaking files executable.\e[0m"
		chmod +x scripts/*
		echo -e "\e[32mRunning 'make clean'.\e[0m"
		make clean
		sleep 10
		echo -e "\e[32mMaking kali_defconfig.\e[0m"
		make kali_defconfig
		# Attach kernel builder to updater-script
		echo -e "\e[32mCopying updater script to working directory.\e[0m"
		cp $maindir/devices/updater-scripts/lollipop/hammerhead $workingdir/flashkernel/META-INF/com/google/android/updater-script

		nhb_kernel_build

		cd $workingdir/flashkernel/kernel
		abootimg --create $workingdir/flashkernel/boot.img -f $workingdir/kernel/ramdisk/5/bootimg.cfg -k $workingdir/kernel/arch/arm/boot/zImage-dtb -r $workingdir/kernel/ramdisk/5/initrd.img
		cd $workingdir
		if [ -d "$workingdir/flash/" ]; then
			cp $workingdir/flashkernel/boot.img $workingdir/flash/boot.img
		fi
}
