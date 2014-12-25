nhb_mako_kitkat(){
	echo -e "\e[32mChecking for existing kernel.\e[0m"
	if [[ -d $maindir/kernel/devices/kitkat/mako ]]; then
		echo -e "\e[32mKernel found.\e[0m"
		echo -e "\e[32mCopying kernel to rootfs.\e[0m"
		cp -rf $maindir/kernel/devices/kitkat/mako $workingdir/kernel
	else
		echo -e "\e[32mKernel not found.\e[0m"
		echo -e "\e[32mDownloading Kernel.\e[0m"
		git clone https://github.com/binkybear/kernel_msm.git -b android-msm-mako-3.4-kitkat-mr2 $maindir/kernel/devices/kitkat/mako
		echo -e "\e[32mCopying kernel to rootfs.\e[0m"
		cp -rf $maindir/kernel/devices/kitkat/mako $workingdir/kernel
	fi
	cd $workingdir/kernel
	echo -e "\e[32mUnzipping ramdisk.\e[0m"
	unzip ramdisk/4.4.4/ramdisk_kitkat.zip -d $workingdir/flashkernel/kernel/
	echo -e "\e[32mRunning 'make clean'.\e[0m"
	make clean
	sleep 10
	echo -e "\e[32mMaking kali_defconfig.\e[0m"
	make kali_defconfig
	echo -e "\e[32mCopying updater script to working directory.\e[0m"
	cp $maindir/devices/updater-scripts/kitkat/mako $workingdir/flashkernel/META-INF/com/google/android/updater-script
	# Start kernel build

	nhb_kernel_build

	cd $workingdir/flashkernel/kernel
	abootimg --create $workingdir/flashkernel/boot.img -f bootimg.cfg -k $workingdir/kernel/arch/arm/boot/zImage -r initrd.img
	cd $workingdir
}
