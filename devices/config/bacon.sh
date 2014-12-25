nhb_bacon_kitkat(){
	echo -e "\e[32mChecking for existing kernel.\e[0m"
	if [[ -d $maindir/kernel/devices/kitkat/bacon ]]; then
		echo -e "\e[32mKernel found.\e[0m"
		echo -e "\e[32mCopying kernel to rootfs.\e[0m"
		cp -rf $maindir/kernel/devices/kitkat/bacon $workingdir/kernel
	else
		echo -e "\e[32mKernel not found.\e[0m"
		echo -e "\e[32mDownloading Kernel.\e[0m"
		git clone https://github.com/binkybear/AK-OnePone.git -b cm-11.0-ak $maindir/kernel/devices/kitkat/bacon
		echo -e "\e[32mCopying kernel to rootfs.\e[0m"
		cp -rf $maindir/kernel/devices/kitkat/bacon $woringdir/kernel
	fi
	cd $workingdir/kernel
	echo -e "\e[32mMaking files executable.\e[0m"
	chmod +x scripts/* ramdisk/4/mkbootimg ramdisk/4/dtbToolCM
	echo -e "\e[32mRunning 'make clean'.\e[0m"
	make clean
	sleep 10
	echo -e "\e[32mMaking kali_defconfig.\e[0m"
	make kali_defconfig
	# Attach kernel builder to updater-script
	echo -e "\e[32mCopying updater script to working directory.\e[0m"
	cp $maindir/devices/updater-scripts/kitkat/bacon $workingdir/flashkernel/META-INF/com/google/android/updater-script
	# Start kernel build

	nhb_kernel_build

	# Start boot.img creation
	cd $workingdir/kernel
	echo -e "\e[32mCreating dt.img.\e[0m"
	$workingdir/kernel/ramdisk/4/dtbToolCM -2 -o $workingdir/flashkernel/kernel/dt.img -s 2048 -p $workingdir/kernel/scripts/dtc/ $workingdir/kernel/arch/arm/boot/
	sleep 3
	echo -e "\e[32mCreating boot.img.\e[0m"
	$workingdir/kernel/ramdisk/4/mkbootimg --kernel arch/arm/boot/zImage --ramdisk ramdisk/4/initrd.img --cmdline "console=ttyHSL0,115200,n8 androidboot.hardware=bacon user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3" --dt ../flashkernel/kernel/dt.img --output ../flashkernel/boot.img
}

nhb_bacon_lollipop(){
	echo -e "\e[32mChecking for existing kernel.\e[0m"
	if [[ -d $maindir/kernel/devices/lollipop/bacon ]]; then
		echo -e "\e[32mKernel found.\e[0m"
			echo -e "\e[32mCopying kernel to rootfs.\e[0m"
			cp -rf $maindir/kernel/devices/lollipop/bacon $workingdir/kernel
	else
		echo -e "\e[32mKernel not found.\e[0m"
		echo -e "\e[32mDownloading kernel.\e[0m"
		git clone https://github.com/binkybear/furnace-bacon.git -b cm-12.0 $maindir/kernel/devices/lollipop/bacon
		echo -e "\e[32mCopying kernel to rootfs.\e[0m"
		cp -rf $maindir/kernel/devices/lollipop/bacon $workingdir/kernel
	fi
	cd $workingdir/kernel
	echo -e "\e[32mMaking files executable.\e[0m"
	chmod +x scripts/* ramdisk/5/mkbootimg ramdisk/5/dtbToolCM
	echo -e "\e[32mRunning 'make clean'.\e[0m"
	make clean
	sleep 10
	echo -e "\e[32mMaking kali_defconfig.\e[0m"
	make kali_defconfig
	# Attach kernel builder to updater-script
	echo -e "\e[32mCopying updater script to working directory.\e[0m"
	cp $maindir/devices/updater-scripts/lollipop/bacon $workingdir/flashkernel/META-INF/com/google/android/updater-script
	# Start kernel build

	nhb_kernel_build

	# Start boot.img creation
	cd $workingdir/kernel
	echo -e "\e[32mCreating dt.img.\e[0m"
	$workingdir/kernel/ramdisk/5/dtbToolCM -2 -o $workingdir/flashkernel/kernel/dt.img -s 2048 -p $workingdir/kernel/scripts/dtc/ $workingdir/kernel/arch/arm/boot/
	sleep 3
	echo -e "\e[32mCreating boot.img.\e[0m"
	$workingdir/kernel/ramdisk/5/mkbootimg --kernel arch/arm/boot/zImage --ramdisk ramdisk/5/initrd.img --cmdline "console=ttyHSL0,115200,n8 androidboot.hardware=bacon user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3 androidboot.selinux=permissive" --dt ../flashkernel/kernel/dt.img --output ../flashkernel/boot.img
}
