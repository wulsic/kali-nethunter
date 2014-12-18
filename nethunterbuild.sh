#!/bin/bash
set -e

### Makse sure all requirements are met
nhb_check(){
  ### Checks to see if host machine is running 64 bit Kali
  hostarch=`uname -m`
  if [ $hostarch == "Darwin" ]; then
    echo -e "\e[34mOS X isn't supported.\e[0m"
    exit
  else
    testkali=$(cat /etc/*-release | grep "ID=kali")
  fi
  if [[ $testkali == "ID=kali"* && ( $hostarch == "x86_64" || $hostarch == "amd64" ) ]]; then
    echo -e "\e[34m64 bit Kali Linux detected.\e[0m"
  else
    echo -e "\e[34mThis utility is only compatible with 64 bit Kali Linux.\e[0m"
    exit
  fi


  ### Checks to see if input matches script's abilities
  ### If nothing is selectd, display error and exit immediately
  if [[ $buildtype == "" ]]&&[[ $androidversion == "" ]]&&[[ $device == "" ]]; then
    echo -e "\e[34mYou must specify arguments in order for the script to work.\e[0m"
    echo -e "\e[34mUse the argument -h to see what arguments are needed.\e[0m"
    exit
  fi
  ### If build type is blank, display error and set $error var to 1
  if [[ $buildtype == "" ]]; then
    echo -e "\e[34mThe build cannot continue because a build type was not specified.\e[0m"
    error=1
  fi
  ### If Kernel build is selected, but no device specified, display error and set $error var to 1
  if [[ $device == "" ]]&&[[ $buildtype == "kernel" ]]; then
    echo -e "\e[34mThe build cannot continue because a device was not specified.\e[0m"
    error=1
  fi
  ### If Kernel build is selected but no android version selected, display error and set $error var to 1
  if [[ $androidversion == "" ]]&&[[ $buildtype == "kernel" ]]; then
    echo -e "\e[34mThe build cannot continue because an Android version was not specified.\e[0m"
    error=1
  fi
  ### If Lollipop kernel is selected for an unsupported device, display error and set $error var to 1
  if [[ $buildtype == "kernel" ]]&&[[ $androidversion == "lollipop" ]]; then
    if [[ $device == "manta" ]]||[[ $device == "groupertilapia" ]]||[[ $device == "mako" ]]||[[ $device == "gs5" ]]||[[ $device == "gs4" ]]; then
      echo -e "\e[34mLollipop isn't currently supported on your device.\e[0m"
      error=1
    fi
  fi
  ### If KitKat kernel is selected for an unsupported device, display error and set $error var to 1
  if [[ $buildtype == "kernel" ]]&&[[ $androidversion == "kitkat" ]]; then
    if [[ $device == "shamu" ]]||[[ $device == "flounder" ]]; then
      echo -e "\e[34mKitKat isn't supported on your device.\e[0m"
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
  export columns=$(tput cols)
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done
  echo -e -n "\e[31m###\e[0m  SETTING UP  "; for ((n=0;n<($columns-17);n++)); do echo -e -n "\e[31m#\e[0m"; done
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done

  ### Sets up variables used throughout the script
  echo -e "\e[34mSetting variables.\e[0m"
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

  echo -e "\e[34mChecking for previous installation.\e[0m"
  ### Checks for existing build directory exists
  if [ -d $maindir ]; then
    echo -e "\e[34mPrevious install found.\e[0m"
    cd $maindir
  else
    echo -e "\e[34mNetHunter build directory not found. Downloading required files...\e[0m"
    echo -e "\e[34mCloning NetHunter files to $maindir.\e[0m"
    git clone -b nethunterbuild https://github.com/offensive-security/kali-nethunter $maindir
    mkdir -p $maindir/rootfs
    ### Make Directories and Prepare to build
    echo -e "\e[34mCloning toolchain to $toolchaindir/gcc-arm-linux-gnueabihf-4.7.\e[0m"
    git clone https://github.com/offensive-security/gcc-arm-linux-gnueabihf-4.7 $toolchaindir/gcc-arm-linux-gnueabihf-4.7
    export PATH=${PATH}:$toolchaindir/gcc-arm-linux-gnueabihf-4.7/bin
    ### Build Dependencies for script
    echo -e "\e[34mUpdating sources.\e[0m"
    apt-get update
    echo -e "\e[34mInstalling dependencies needed to build NetHunter.\e[0m"
    apt-get install -y git-core gnupg flex bison gperf libesd0-dev build-essential zip curl libncurses5-dev zlib1g-dev libncurses5-dev gcc-multilib g++-multilib \
    parted kpartx debootstrap pixz qemu-user-static abootimg cgpt vboot-kernel-utils vboot-utils uboot-mkimage bc lzma lzop automake autoconf m4 dosfstools pixz rsync \
    schedtool git dosfstools e2fsprogs device-tree-compiler ccache dos2unix zip
    echo -e "\e[34mdetermining host architecture.\e[0m"
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
    echo -e "\e[34mChecking for /usr/bin/lz4c.\e[0m"
    if [ ! -e "/usr/bin/lz4c" ]; then
      echo -e "\e[34mDownloading and making lz4c for system:\e[0m"
      cd $maindir
      wget http://lz4.googlecode.com/files/lz4-r112.tar.gz
      tar -xf lz4-r112.tar.gz
      cd lz4-r112
      make
      make install
      echo -e "\e[34mlz4c now installed. Removing leftover files.\e[0m"
      cd ..
      rm -rf lz4-r112.tar.gz lz4-r112
    fi
    cd $maindir
  fi

  echo -e "\e[34mProcessing kernel build scripts.\e[0m"
  ### Reads sub-scripts for various functions for kernel building
  source $maindir/devices/config/shamu.sh
  source $maindir/devices/config/flounder.sh
  source $maindir/devices/config/hammerhead.sh
  source $maindir/devices/config/manta.sh
  source $maindir/devices/config/groupertilapia.sh
  source $maindir/devices/config/flodeb.sh
  source $maindir/devices/config/mako.sh
  source $maindir/devices/config/bacon.sh

  echo -e "\e[34mChecking NetHunter directory for any updated files.\e[0m"
  ### Makes sure all of the files are up to date
  cd $maindir
  for directory in $(ls -l |grep ^d|awk -F" " '{print $9}');do cd $directory && git pull && cd ..;done
  cd $maindir
  if [ -d "$workingdir" ]; then
    echo -e "\e[34mDelete previous working directory.\e[0m"
    rm -rf $workingdir
  fi
  echo -e "\e[34mCreating working directory.\e[0m"
  mkdir -p $workingdir
  cd $workingdir
}

### Calls outside scripts to do the actual building
nhb_build(){
  case $buildtype in
    rootfs)
      echo -e "\e[34mStarting RootFS build.\e[0m"
      $rootfsbuild
      echo -e "\e[34mRootFS build complete.\e[0m";;
    kernel)
      echo -e "\e[34mStarting kernel build.\e[0m"
      $kernelbuild
      echo -e "\e[34mKernel build complete.\e[0m";;
    all)
      echo -e "\e[34mStarting RootFS Build.\e[0m"
      $rootfsbuild
      echo -e "\e[34mRootFS build complete.\e[0m"
      echo -e "\e[34mStarting Kernel build.\e[0m"
      $kernelbuild
      echo -e "\e[34mKernel build complete.\e[0m";;
  esac
}

### Moves built files to output directory
nhb_output(){
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done
  echo -e -n "\e[31m###\e[0m  MOVING TO OUTPUT  "; for ((n=0;n<($columns-23);n++)); do echo -e -n "\e[31m#\e[0m"; done
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done

  if [[ -a $workingdir/NetHunter-$date.zip ]]&&[[ -a $workingdir/NetHunter-$date.sha1sum ]]; then
    echo -e "\e[34mMoving NetHunter RootFS and SHA1 sum from working directory to output directory.\e[0m"
    cd $workingdir
    mkdir -p $outputdir/RootFS
    mv update-kali-$date.zip $outputdir/RootFS/NetHunter-$date.zip
    mv update-kali-$date.sha1sum $outputdir/RootFS/NetHunter-$date.sha1sum
    echo -e "\e[34mNetHunter is now located at $outputdir/RootFS/NetHunter-$date.zip\e[0m"
    echo -e "\e[34mNetHunter's SHA1 sum located at $outputdir/RootFS/NetHunter-$date.sha1sum\e[0m"
  fi
  if [[ -a $workingdir/Kernel-$device-$androidversion-$date.zip ]]&&[[ -a $workingdir/Kernel-$device-$androidversion-$date.sha1sum ]]; then
    echo -e "\e[34mMoving kernel and SHA1 sum from working directory to output directory.\e[0m"
    cd $workingdir
    mkdir -p $outputdir/Kernels/$device
    mv kernel-kali-$date.zip $outputdir/Kernels/$device/Kernel-$device-$androidversion-$date.zip
    mv kernel-kali-$date.sha1sum $outputdir/Kernels/$device/Kernel-$device-$androidversion-$date.sha1sum
    echo -e "\e[34mKernel is located at $outputdir/Kernels/$device/Kernel-$device-$androidversion-$date.zip\e[0m"
    echo -e "\e[34mKernel's SHA1 sum located at $outputdir/Kernels/$device/Kernel-$device-$androidversion-$date.sha1sum\e[0m"
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
        *) echo -e "\e[34mInvalid build type: $OPTARG\e[0m"; exit;;
      esac;;
    v)
      case $OPTARG in
        lollipop|Lollipop) androidversion=lollipop;;
        kitkat|KitKat) androidversion=kitkat;;
        *) echo -e "\e[34mInvalid Android version selected: $OPTARG\e[0m"; exit;;
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
        *) echo -e "\e[34mInvalid device selected: $OPTARG\e[0m"; exit;;
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
          echo -e "\e[34mThere was an error creating the directory. Make sure it is correct before continuing.\e[0m"
          exit
        fi
      fi;;
    d)
      echo -e "\e[34mDebugging mode: On\e[0m"
      DEBUG=1;;
    k)
      keepfiles=1;;
    h)
      clear
      echo -e "\e[34m##################################\e[37m NetHunter Help Menu \e[31m###################################\e[0m"
      echo -e "\e[34m#######\e[37m e.g. ./nethunterbuilder.sh -b kernel -t grouper -a lollipop -o ~/build \e[31m###########\e[0m"
      echo -e "\e[34m###\e[37m Options \e[31m##############################################################################\e[0m"
      echo -e  "-h               \e[31m||\e[0m This help menu"
      echo -e  "-b [type]        \e[31m||\e[0m Build type"
      echo -e  "-t [device]      \e[31m||\e[0m Android device to build for (Kernel buids only)"
      echo -e  "-v [Version]     \e[31m||\e[0m Android version to build for (Kernel buids only)"
      echo -e  "-o [directory]   \e[31m||\e[0m Where the files are output (Defaults to ~/NetHunter-Builds)"
      echo -e  "-k               \e[31m||\e[0m Keep previously downloaded files (If they exist)"
      echo -e  "-d               \e[31m||\e[0m Turn debug mode on"
      echo -e "\e[34m###\e[37m Devices \e[31m##############################################################################\e[0m"
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
      echo -e "\e[34m###\e[37m Build Types \e[31m##########################################################################\e[0m"
      echo -e  "all              \e[31m||\e[0m Builds kernel and RootFS (Requires -t and -a arguments)"
      echo -e  "kernel           \e[31m||\e[0m Builds just a kernel (Requires -t and -a arguments)"
      echo -e  "rootfs           \e[31m||\e[0m Builds Nethunter RootFS"
      echo -e "\e[34m###\e[37m Versions \e[31m#############################################################################\e[0m"
      echo -e  "lollipop         \e[31m||\e[0m Android 5.0 Lollipop"
      echo -e  "kitkat           \e[31m||\e[0m Android 4.4.2 - 4.4.4 KitKat"
      echo -e "\e[34m##########################################################################################\e[0m"
      exit;;
  esac
done

nhb_check
nhb_setup
nhb_build
nhb_output
