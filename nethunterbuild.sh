#!/bin/bash
set -e

### Makse sure all requirements are met
nhb_check(){
  ### Checks to see if host machine is running 64 bit Kali
  hostarch=`uname -m`
  if [ $hostarch == "Darwin" ]; then
    echo "OS X isn't supported"
    exit
  else
    testkali=$(cat /etc/*-release | grep "ID=kali")
  fi
  if [[ $testkali == "ID=kali"* && ( $hostarch == "x86_64" || $hostarch == "amd64" ) ]]; then
    echo "64 bit Kali Linux detected"
  else
    echo "This utility is only compatible with 64 bit Kali Linux."
    exit
  fi


  ### Checks to see if input matches script's abilities
  ### If nothing is selectd, display error and exit immediately
  if [[ $buildtype == "" ]]&&[[ $androidversion == "" ]]&&[[ $device == "" ]]; then
    echo "You must specify arguments in order for the script to work."
    echo "Use the argument -h to see what arguments are needed."
    exit
  fi
  ### If build type is blank, display error and set $error var to 1
  if [[ $buildtype == "" ]]; then
    echo "The build cannot continue because a build type was not specified."
    error=1
  fi
  ### If Kernel build is selected, but no device specified, display error and set $error var to 1
  if [[ $device == "" ]]&&[[ $buildtype == "kernel" ]]; then
    echo "The build cannot continue because a device was not specified."
    error=1
  fi
  ### If Kernel build is selected but no android version selected, display error and set $error var to 1
  if [[ $androidversion == "" ]]&&[[ $buildtype == "kernel" ]]; then
    echo "The build cannot continue because an Android version was not specified."
    error=1
  fi
  ### If Lollipop kernel is selected for an unsupported device, display error and set $error var to 1
  if [[ $buildtype == "kernel" ]]&&[[ $androidversion == "lollipop" ]]; then
    if [[ $device == "manta" ]]||[[ $device == "groupertilapia" ]]||[[ $device == "mako" ]]||[[ $device == "gs5" ]]||[[ $device == "gs4" ]]; then
      echo "Lollipop isn't currently supported on your device."
      error=1
    fi
  fi
  ### If KitKat kernel is selected for an unsupported device, display error and set $error var to 1
  if [[ $buildtype == "kernel" ]]&&[[ $androidversion == "kitkat" ]]; then
    if [[ $device == "shamu" ]]||[[ $device == "flounder" ]]; then
      echo "KitKat isn't supported on your device."
      error=1
    fi
  fi

  ### Displays the errors above and exits
  if [[ $error == 1 ]]; then
    exit
  fi
}

### Sets up variables and dependencies
nhb_setup(){
  ### Sets up variables used throughout the script
  export date=$(date +%m%d%Y)
  export architecture="armhf"
  export maindir=~/NetHunter
  export workingdir=$maindir/working-directory-$date
  export rootfsdir=$maindir/rootfs
  export kalirootfs=$rootfsdir/kali-$architecture
  export boottools=$maindir/files/bin/boottools
  export toolchaindir=$maindir/files/toolchains
  export rootfsbuild="source $maindir/scripts/rootfsbuild.sh"
  export kernelbuild="source $maindir/scripts/kernelbuild.sh"

  ### Checks for existing build directory exists
  if [ -d "$toolchains" ]&&[ -d "$rootfsdir" ]; then
    echo "Previous install found"
    cd $maindir
  else
    echo "NetHunter build directory not found. Installing..."
    git clone -b nethunterbuild https://github.com/offensive-security/kali-nethunter $maindir
    mkdir -p $maindir/rootfs
    ### Make Directories and Prepare to build
    git clone https://github.com/offensive-security/gcc-arm-linux-gnueabihf-4.7 $toolchaindir/gcc-arm-linux-gnueabihf-4.7
    export PATH=${PATH}:$toolchaindir/gcc-arm-linux-gnueabihf-4.7/bin
    ### Build Dependencies for script
    apt-get update
    apt-get install -y git-core gnupg flex bison gperf libesd0-dev build-essential zip curl libncurses5-dev zlib1g-dev libncurses5-dev gcc-multilib g++-multilib \
    parted kpartx debootstrap pixz qemu-user-static abootimg cgpt vboot-kernel-utils vboot-utils uboot-mkimage bc lzma lzop automake autoconf m4 dosfstools pixz rsync \
    schedtool git dosfstools e2fsprogs device-tree-compiler ccache dos2unix
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
    if [ ! -e "/usr/bin/lz4c" ]; then
      echo "Missing lz4c which is needed to build certain kernels.  Downloading and making for system:"
      cd $maindir
      wget http://lz4.googlecode.com/files/lz4-r112.tar.gz
      tar -xf lz4-r112.tar.gz
      cd lz4-r112
      make
      make install
      echo "lz4c now installed.  Removing leftover files."
      cd ..
      rm -rf lz4-r112.tar.gz lz4-r112
    fi
    cd $maindir
  fi

  ### Reads sub-scripts for various functions for kernel building
  source $maindir/devices/config/shamu.sh
  source $maindir/devices/config/flounder.sh
  source $maindir/devices/config/hammerhead.sh
  source $maindir/devices/config/manta.sh
  source $maindir/devices/config/grouper-tilapia.sh
  source $maindir/devices/config/flo-deb.sh
  source $maindir/devices/config/mako.sh
  source $maindir/devices/config/bacon.sh

  ### Makes sure all of the files are up to date
  cd $maindir
  for directory in $(ls -l |grep ^d|awk -F" " '{print $9}');do cd $directory && git pull && cd ..;done
  cd $maindir
  if [ -d "$workingdir" ]; then
    rm -rf $workingdir
  fi
  mkdir -p $workingdir
  cd $workingdir
}

### Calls outside scripts to do the actual building
nhb_build(){
  case $buildtype in
    rootfs) $rootfsbuild;;
    kernel) $kernelbuild;;
    all) $rootfsbuild; $kernelbuild;;
  esac
}

### Moves built files to output directory
nhb_output(){
  if [[ -a $workingdir/NetHunter-$date.zip ]]&&[[ -a $workingdir/NetHunter-$date.sha1sum ]]; then
    cd $workingdir
    mkdir -p $outputdir/RootFS
    mv update-kali-$date.zip $outputdir/RootFS/NetHunter-$date.zip
    mv update-kali-$date.sha1sum $outputdir/RootFS/NetHunter-$date.sha1sum
    echo "NetHunter is now located at $outputdir/RootFS/NetHunter-$date.zip"
    echo "NetHunter's SHA1 sum located at $outputdir/RootFS/NetHunter-$date.sha1sum"
  fi
  if [[ -a $workingdir/Kernel-$selecteddevice-$targetver-$builddate.zip ]]&&[[ -a $workingdir/Kernel-$selecteddevice-$targetver-$builddate.sha1sum ]]; then
    cd $workingdir
    mkdir -p $outputdir/Kernels/$device
    mv kernel-kali-$date.zip $outputdir/Kernels/$device/Kernel-$device-$androidversion-$date.zip
    mv kernel-kali-$date.sha1sum $outputdir/Kernels/$device/Kernel-$device-$androidversion-$date.sha1sum
    echo "Kernel is located at $outputdir/Kernels/$device/Kernel-$device-$androidversion-$date.zip"
    echo "Kernel's SHA1 sum located at $outputdir/Kernels/$device/Kernel-$device-$androidversion-$date.sha1sum"
  fi
  rm -rf $workingdir
}

### Defaults for script
outputdir=~/NetHunter-Builds

### Arguments for the script
while getopts "b:v:t:o:dkh" flag; do
  case "$flag" in
    b)
      case $OPTARG in
        kernel)
        buildtype="kernel";;
        rootfs)
        buildtype="rootfs";;
        all)
        buildtype="all";;
        *) echo "Invalid build type: $OPTARG"; exit;;
      esac;;
    v)
      case $OPTARG in
        lollipop|Lollipop) androidversion=lollipop;;
        kitkat|KitKat) androidversion=kitkat;;
        *) echo "Invalid Android version selected: $OPTARG"; exit;;
      esac;;
    t)
      case $OPTARG in
        manta) device="manta";;
        grouper|tilapia|groupertilapia|tilapiagrouper) device="groupertilapia";;
        flo|deb|flodeb|debflo) device="flodeb";;
        mako) device="mako";;
        hammerhead) device="hammerhead";;
        shamu) device="shamu";;
        flounder) device="flounder";;
        bacon) device="bacon";;
        *) echo "Invalid device selected: $OPTARG"; exit;;
      esac;;
    o)
      outputdir=$OPTARG
      if [ -d "$outputdir" ]; then
        sleep 0
      else
        mkdir -p $outputdir
        if [ -d "$outputdir" ]; then
          sleep 0
        else
          echo "There was an error creating the directory. Make sure it is correct before continuing."
          exit
        fi
      fi;;
    d)
      echo "Debugging mode: On"
      DEBUG=1;;
    k)
      keepfiles=1;;
    h)
      clear
      echo -e "\e[31m##################################\e[37m NetHunter Help Menu \e[31m###################################\e[0m"
      echo -e "\e[31m###e.g. ./nethunterbuilder.sh -b kernel -t grouper -a lollipop -o ~/newbuild                       ###\e[0m"
      echo -e "\e[31m###\e[37m Options \e[31m##############################################################################\e[0m"
      echo -e  "-h               \e[31m||\e[0m This help menu"
      echo -e  "-b [type]        \e[31m||\e[0m Build type"
      echo -e  "-t [device]      \e[31m||\e[0m Android device to build for (Kernel buids only)"
      echo -e  "-v [Version]     \e[31m||\e[0m Android version to build for (Kernel buids only)"
      echo -e  "-o [directory]   \e[31m||\e[0m Where the files are output (Defaults to ~/NetHunter-Builds)"
      echo -e  "-k               \e[31m||\e[0m Keep previously downloaded files (If they exist)"
      echo -e  "-d               \e[31m||\e[0m Turn debug mode on"
      echo -e "\e[31m###\e[37m Devices \e[31m##############################################################################\e[0m"
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
      echo -e "\e[31m###\e[37m Build Types \e[31m##########################################################################\e[0m"
      echo -e  "all              \e[31m||\e[0m Builds kernel and RootFS (Requires -t and -a arguments)"
      echo -e  "kernel           \e[31m||\e[0m Builds just a kernel (Requires -t and -a arguments)"
      echo -e  "rootfs           \e[31m||\e[0m Builds Nethunter RootFS"
      echo -e "\e[31m###\e[37m Versions \e[31m#############################################################################\e[0m"
      echo -e  "lollipop         \e[31m||\e[0m Android 5.0 Lollipop"
      echo -e  "kitkat           \e[31m||\e[0m Android 4.4.2 - 4.4.4 KitKat"
      echo -e "\e[31m##########################################################################################\e[0m"
      exit;;
  esac
done

nhb_check
nhb_setup
nhb_build
nhb_output
echo "Build complete."
