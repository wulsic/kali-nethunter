#!/bin/bash
set -e

### Makse sure all requirements are met
nhb_check(){
  ### Checks to see if host machine is running 64 bit Kali
  hostarch=`uname -m`
  if [ $hostarch == "Darwin" ]; then
    echo -e "\e[32mOS X isn't supported.\e[0m"
    exit
  else
    testkali=$(cat /etc/*-release | grep "ID=kali")
  fi
  if [[ $testkali == "ID=kali"* && ( $hostarch == "x86_64" || $hostarch == "amd64" ) ]]; then
    echo -e "\e[32m64 bit Kali Linux detected.\e[0m"
  else
    echo -e "\e[32mThis utility is only compatible with 64 bit Kali Linux.\e[0m"
    exit
  fi


  ### Checks to see if input matches script's abilities
  ### If nothing is selectd, display error and exit immediately
  if [[ $buildtype == "" ]]&&[[ $androidversion == "" ]]&&[[ $device == "" ]]; then
    echo -e "\e[32mYou must specify arguments in order for the script to work.\e[0m"
    echo -e "\e[32mUse the argument -h to see what arguments are needed.\e[0m"
    exit
  fi
  ### If build type is blank, display error and set $error var to 1
  if [[ $buildtype == "" ]]; then
    echo -e "\e[32mThe build cannot continue because a build type was not specified.\e[0m"
    error=1
  fi
  ### If Kernel build is selected, but no device specified, display error and set $error var to 1
  if [[ $device == "" && ( $buildtype == "kernel" || $buildtype == "both" ) ]]; then
    echo -e "\e[32mThe build cannot continue because a device was not specified.\e[0m"
    error=1
  fi
  ### If Kernel build is selected but no android version selected, display error and set $error var to 1
  if [[ $androidversion == "" && ( $buildtype == "kernel" || $buildtype == "both" ) ]]; then
    echo -e "\e[32mThe build cannot continue because an Android version was not specified.\e[0m"
    error=1
  fi

  ### Displays the errors above and exits
  if [[ $error == 1 ]]; then
    exit
  fi
}

### Sets up variables and dependencies
nhb_setup(){
  export columns=$(tput cols)
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  echo -e -n "\e[31m###\e[0m  SETTING UP  "; for ((n=0;n<($columns-17);n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo

  ### Sets up variables used throughout the script
  echo -e "\e[32mSetting variables.\e[0m"
  export date=$(date +%m%d%Y)
  export architecture="armhf"
  export maindir=~/NetHunter
  export workingdir=$maindir/working-directory
  export rootfsdir=$maindir/rootfs
  export kalirootfs=$rootfsdir/kali-$architecture
  export boottools=$maindir/files/bin/boottools
  export toolchaindir=$maindir/files/toolchains
  export rootfsbuild="source $maindir/scripts/rootfsbuild.sh"
  export kernelbuild="source $maindir/scripts/kernelbuild.sh"

  echo -e "\e[32mChecking for previous installation.\e[0m"
  ### Checks for existing build directory exists
  if [ -d $maindir ]; then
    echo -e "\e[32mPrevious install found.\e[0m"
    cd $maindir
  else
    echo -e "\e[32mNetHunter build directory not found. Downloading required files...\e[0m"
    echo -e "\e[32mCloning NetHunter files to $maindir.\e[0m"
    git clone -b nethunterbuild https://github.com/offensive-security/kali-nethunter $maindir
    mkdir -p $maindir/rootfs
    ### Make Directories and Prepare to build
    echo -e "\e[32mCloning toolchain to $toolchaindir/gcc-arm-linux-gnueabihf-4.7.\e[0m"
    git clone https://github.com/offensive-security/gcc-arm-linux-gnueabihf-4.7 $toolchaindir/gcc-arm-linux-gnueabihf-4.7
    export PATH=${PATH}:$toolchaindir/gcc-arm-linux-gnueabihf-4.7/bin
    ### Build Dependencies for script
    echo -e "\e[32mUpdating sources.\e[0m"
    apt-get update
    echo -e "\e[32mInstalling dependencies needed to build NetHunter.\e[0m"
    apt-get install -y git-core gnupg flex bison gperf libesd0-dev build-essential zip curl libncurses5-dev zlib1g-dev libncurses5-dev gcc-multilib g++-multilib \
    parted kpartx debootstrap pixz qemu-user-static abootimg cgpt vboot-kernel-utils vboot-utils uboot-mkimage bc lzma lzop automake autoconf m4 dosfstools pixz rsync \
    schedtool git dosfstools e2fsprogs device-tree-compiler ccache dos2unix zip
    echo -e "\e[32mDetermining host architecture.\e[0m"
    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == 'x86_64' ]; then
      dpkg --add-architecture i386
      apt-get update
      apt-get install -y ia32-libs
      # Required for kernel cross compiles
      apt-get install -y libncurses5:i386
    else
      apt-get install -y libncurses5
    fi
    echo -e "\e[32mChecking for /usr/bin/lz4c.\e[0m"
    if [ ! -e "/usr/bin/lz4c" ]; then
      echo -e "\e[32mDownloading and making lz4c for system:\e[0m"
      cd $maindir
      wget http://lz4.googlecode.com/files/lz4-r112.tar.gz
      tar -xf lz4-r112.tar.gz
      cd lz4-r112
      make
      make install
      echo -e "\e[32mlz4c now installed. Removing leftover files.\e[0m"
      cd ..
      rm -rf lz4-r112.tar.gz lz4-r112
    fi
    cd $maindir
  fi

  echo -e "\e[32mProcessing kernel build scripts.\e[0m"
  ### Reads sub-scripts for various functions for kernel building
  rm -rf $maindir/devices/.devices
  rm -rf $maindir/devices/.lollipopdevices
  rm -rf $maindir/devices/.kitkatdevices

  for kernelconfigs in $(ls -l $maindir/devices/config | grep .sh | awk -F" " '{print $9}');do source $maindir/devices/config/$kernelconfigs && echo "$kernelconfigs" >> $maindir/devices/.devices;done
  sed -i 's/.sh//g' $maindir/devices/.devices

  if [[ $device != "" ]]; then
    if [[ "$device" != $(cat $maindir/devices/.devices | grep $device) ]]; then
      echo -e "\e[32mThe build script for $device was not found in $maindir/devices/config/.\e[0m"
      exit
    fi
  fi

  for product in $(cat $maindir/devices/.devices);do
    if grep -q nhb_${product}_lollipop "$maindir/devices/config/$product.sh"; then
      echo "$product" >> $maindir/devices/.lollipopdevices
    fi
    if grep -q nhb_${product}_kitkat "$maindir/devices/config/$product.sh"; then
      echo "$product" >> $maindir/devices/.kitkatdevices
    fi
  done

  for product in $(cat $maindir/devices/.lollipopdevices);do
    if [[ ! -f $maindir/devices/updater-scripts/lollipop/$product ]]; then
      echo -e "\e[32mupdater-script for $product not found in $maindir/devices/updater-scripts/lollipop/.\e[0m"
      exit
    fi
  done
  for product in $(cat $maindir/devices/.kitkatdevices);do
    if [[ ! -f $maindir/devices/updater-scripts/kitkat/$product ]]; then
      echo -e "\e[32mupdater-script for $product not found in $maindir/devices/updater-scripts/kitkat/.\e[0m"
      exit
    fi
  done

  echo -e "\e[32mChecking NetHunter directory for any updated files.\e[0m"
  ### Makes sure all of the files are up to date
  cd $maindir
  for directory in $(ls -l |grep ^d|awk -F" " '{print $9}');do cd $maindir/$directory && git pull && cd ..;done
  cd $maindir
  if [ -d "$workingdir" ]; then
    echo -e "\e[32mDelete previous working directory.\e[0m"
    rm -rf $workingdir
  fi
  echo -e "\e[32mCreating working directory.\e[0m"
  mkdir -p $workingdir
  cd $workingdir

  ### If -k was selected as argument, keep existing files, otherwise delete and redownload
  if [[ $keepfiles == 1 ]]; then
    echo -e "\e[32mKeeping existing build files.\e[0m"
  else
    echo -e "\e[32mDeleting existing build files.\e[0m"
    if [[ $buildtype == "rootfs" ]]||[[ $buildtype == "both" ]]||[[ $buildtype == "all" ]]; then
      echo -e "\e[32mDeleting rootfs.\e[0m"
      rm -rf $rootfsdir/*
      echo -e "\e[32mDeleting toolchain (gcc-arm-linux-gnueabihf-4.7) .\e[0m"
      rm -rf $maindir/files/toolchains/gcc-arm-linux-gnueabihf-4.7
    fi
    if [[ $buildtype == "all" ]]||[[ $buildtype == "allkernels" ]]; then
      echo -e "\e[32mDeleting kernels for all devices.\e[0m"
      rm -rf $maindir/kernel/devices/*
      cd $maindir/files/toolchains
      echo -e "\e[32mDeleting toolchains.\e[0m"
      ls | grep -v 'gcc-arm-linux-gnueabihf-4.7' | xargs rm -rf
    elif [[ $buildtype == "both" ]]||[[ $buildtype == "kernel" ]]; then
      echo -e "\e[32mDeleting $device kernel.\e[0m"
      rm -rf $maindir/kernel/devices/$androidversion/$device
      cd $maindir/files/toolchains
      echo -e "\e[32mDeleting toolchains.\e[0m"
      ls | grep -v 'gcc-arm-linux-gnueabihf-4.7' | xargs rm -rf
    fi
    cd $workingdir
  fi
}

### Calls outside scripts to do the actual building
nhb_build(){
  case $buildtype in
    rootfs)
      echo -e "\e[32mStarting RootFS build.\e[0m"
      $rootfsbuild
      echo -e "\e[32mRootFS build complete.\e[0m"
      nhb_output;;
    kernel)
      echo -e "\e[32mStarting kernel build.\e[0m"
      $kernelbuild
      echo -e "\e[32mKernel build complete.\e[0m"
      nhb_output;;
    both)
      echo -e "\e[32mStarting RootFS Build.\e[0m"
      $rootfsbuild
      echo -e "\e[32mRootFS build complete.\e[0m"
      echo -e "\e[32mStarting Kernel build.\e[0m"
      $kernelbuild
      echo -e "\e[32mKernel build complete.\e[0m"
      if [[ $combine == 1 ]]; then
        nhb_combine
        nhb_output
      else
        nhb_output
      fi;;
    all)
      echo -e "\e[32mStarting RootFS Build.\e[0m"
      $rootfsbuild
      echo -e "\e[32mRootFS build complete.\e[0m"
      nhb_output
      echo -e "\e[32mStarting Kernel build.\e[0m"
      $kernelbuild
      echo -e "\e[32mKernel build complete.\e[0m";;
    allkernels)
      echo -e "\e[32mStarting Kernel build.\e[0m"
      $kernelbuild
      echo -e "\e[32mKernel build complete.\e[0m";;
  esac
}

nhb_combine(){
  if [[ -a $workingdir/NetHunter-$date.zip ]]&&[[ $workingdir/Kernel-$device-$androidversion-$date.zip ]]; then
    export columns=$(tput cols)
    for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
    echo -e -n "\e[31m###\e[0m  COMBINING ROOTFS AND KERNEL  "; for ((n=0;n<($columns-34);n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
    for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo


}

### Moves built files to output directory
nhb_output(){
  export columns=$(tput cols)
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  echo -e -n "\e[31m###\e[0m  MOVING TO OUTPUT  "; for ((n=0;n<($columns-23);n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo

  if [[ -a $workingdir/NetHunter-$date.zip ]]&&[[ -a $workingdir/NetHunter-$date.sha1sum ]]; then
    echo -e "\e[32mMoving NetHunter RootFS and SHA1 sum from working directory to output directory.\e[0m"
    mkdir -p $outputdir/RootFS
    mv $workingdir/NetHunter-$date.zip $outputdir/RootFS/NetHunter-$date.zip
    mv $workingdir/NetHunter-$date.sha1sum $outputdir/RootFS/NetHunter-$date.sha1sum
    echo -e "\e[32mNetHunter is now located at \e[33m$outputdir/RootFS/NetHunter-$date.zip\e[0m"
    echo -e "\e[32mNetHunter's SHA1 sum located at \e[33m$outputdir/RootFS/NetHunter-$date.sha1sum\e[0m"
  fi
  if [[ -a $workingdir/Kernel-$device-$androidversion-$date.zip ]]&&[[ -a $workingdir/Kernel-$device-$androidversion-$date.sha1sum ]]; then
    echo -e "\e[32mMoving kernel and SHA1 sum from working directory to output directory.\e[0m"
    mkdir -p $outputdir/Kernels/$device
    mv $workingdir/Kernel-$device-$androidversion-$date.zip $outputdir/Kernels/$device/Kernel-$device-$androidversion-$date.zip
    mv $workingdir/Kernel-$device-$androidversion-$date.sha1sum $outputdir/Kernels/$device/Kernel-$device-$androidversion-$date.sha1sum
    echo -e "\e[32mKernel is located at \e[33m$outputdir/Kernels/$device/Kernel-$device-$androidversion-$date.zip\e[0m"
    echo -e "\e[32mKernel's SHA1 sum located at \e[33m$outputdir/Kernels/$device/Kernel-$device-$androidversion-$date.sha1sum\e[0m"
  fi
  rm -rf $workingdir/*
}


### Defaults for script
outputdir=~/NetHunter-Builds

### Arguments for the script
while getopts "b:v:t:o:kh" flag; do
  case "$flag" in
    b)
      case $OPTARG in
        kernel)
          buildtype="kernel";;
        rootfs)
          buildtype="rootfs";;
        all)
          buildtype="all";;
        allkernels)
          buildtype="allkernels";;
        both)
          buildtype="both";;
        *) echo -e "\e[32mInvalid build type: $OPTARG\e[0m"; exit;;
      esac;;
    v)
      case $OPTARG in
        lollipop|Lollipop) androidversion=lollipop;;
        kitkat|KitKat) androidversion=kitkat;;
        *) echo -e "\e[32mInvalid Android version selected: $OPTARG\e[0m"; exit;;
      esac;;
    t)
      device=$OPTARG;;
    o)
      outputdir=$OPTARG
      if [ -d "$outputdir" ]; then
        sleep 0
      else
        mkdir -p $outputdir
        if [ -d "$outputdir" ]; then
          sleep 0
        else
          echo -e "\e[32mThere was an error creating the directory. Make sure it is correct before continuing.\e[0m"
          exit
        fi
      fi;;
    k)
      keepfiles=1;;
    h)
      clear
      export columns=$(tput cols)
      echo -e "\e[31m###\e[37m NetHunter Help Menu \e[0m"; for ((n=0;n<($columns-24);n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
      echo -e -n "\e[31m###\e[37m e.g. ./nethunterbuilder.sh -b kernel -t grouper -a lollipop -o ~/build \e[0m"; for ((n=0;n<($columns-75);n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
      echo -e -n "\e[31m###\e[37m Options "; for ((n=0;n<($columns-12);n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
      echo -e  "-h               \e[31m||\e[0m This help menu"
      echo -e  "-b [type]        \e[31m||\e[0m Build type"
      echo -e  "-t [device]      \e[31m||\e[0m Android device to build for (Kernel buids only)"
      echo -e  "-v [Version]     \e[31m||\e[0m Android version to build for (Kernel buids only)"
      echo -e  "-o [directory]   \e[31m||\e[0m Where the files are output (Defaults to ~/NetHunter-Builds)"
      echo -e  "-k               \e[31m||\e[0m Keep previously downloaded files (If they exist)"
      echo -e -n "\e[31m###\e[37m Devices "; for ((n=0;n<($columns-12);n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
      echo -e  "manta            \e[31m||\e[0m Nexus 10"
      echo -e  "grouper          \e[31m||\e[0m Nexus 7 (2012) Wifi"
      echo -e  "tilapia          \e[31m||\e[0m Nexus 7 (2012) 3G"
      echo -e  "flo              \e[31m||\e[0m Nexus 7 (2013) Wifi"
      echo -e  "deb              \e[31m||\e[0m Nexus 7 (2013) LTE"
      echo -e  "mako             \e[31m||\e[0m Nexus 4"
      echo -e  "hammerhead       \e[31m||\e[0m Nexus 5"
      echo -e  "shamu            \e[31m||\e[0m Nexus 6"
      echo -e  "flounder         \e[31m||\e[0m Nexus 9 Wifi"
      echo -e  "bacon            \e[31m||\e[0m OnePlus One"
      echo -e -n "\e[31m###\e[37m Build Types \e[0m"; for ((n=0;n<($columns-16);n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
      echo -e  "all              \e[31m||\e[0m Builds rootfs and kernels for all devices"
      echo -e  "both             \e[31m||\e[0m Builds kernel and RootFS (Requires -t and -a arguments)"
      echo -e  "kernel           \e[31m||\e[0m Builds just a kernel (Requires -t and -a arguments)"
      echo -e  "allkernels       \e[31m||\e[0m Builds all kernels for all avaliable devices"
      echo -e  "rootfs           \e[31m||\e[0m Builds Nethunter RootFS"
      echo -e -n "\e[31m###\e[37m Versions \e[0m"; for ((n=0;n<($columns-13);n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
      echo -e  "lollipop         \e[31m||\e[0m Android 5.0 Lollipop"
      echo -e  "kitkat           \e[31m||\e[0m Android 4.4.2 - 4.4.4 KitKat"
      for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
      exit;;
  esac
done

nhb_check
nhb_setup
nhb_build
echo -e "\e[32mProcess complete. You can find all files in \e[33m$outputdir\e[0m"
