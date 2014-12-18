#####################################################
# Create Nexus 7 Grouper Kernel (4.4+)
#####################################################
f_nexus7_grouper_kernel(){
	f_kernel_build_init

	echo "Downloading Kernel"
	# Kangaroo Kernel has y-cable support and kexec patch built in
	if [[ -d $maindir/kernel/devices/groupertilapia-kitkat ]]; then
		echo "Copying kernel to rootfs"
		cp -rf $maindir/kernel/devices/groupertilapia-kitkat $workingdir/kernel
	else
		git clone https://github.com/binkybear/kangaroo.git -b kangaroo $maindir/kernel/devices/groupertilapia-kitkat
		cp -rf $maindir/kernel/devices/groupertilapia-kitkat $workingdir/kernel
	fi
	cd $workingdir/kernel
	make clean
	sleep 3
	make kali_defconfig
	# Attach kernel builder to updater-script
	cp $basepwd/devices/updater-scripts/kitkat/groupertilapia $workingdir/flashkernel/META-INF/com/google/android/updater-script

	f_kernel_build
}
