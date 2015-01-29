#!/bin/bash
set -e

nhb_setup(){
  ###################
  ### BUILD SETUP ###
  ###################
  if [[ -d $toolchaindir/gcc-arm-linux-gnueabihf-4.7 ]]; then
    echo -e "\e[32mUsing previously downloaded toolchain.\e[0m"
  else
    echo -e "\e[32mDownloading toolchain.\e[0m"
    git clone https://github.com/offensive-security/gcc-arm-linux-gnueabihf-4.7 $toolchaindir/gcc-arm-linux-gnueabihf-4.7
    echo -e "\e[32mExporting PATH variable.\e[0m"
    export PATH=${PATH}:$toolchaindir/gcc-arm-linux-gnueabihf-4.7/bin
  fi
  unset CROSS_COMPILE
  # Set working folder to rootfs
  cd $workingdir
}

nhb_stage1(){
  export columns=$(tput cols)
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  echo -e -n "\e[31m###\e[0m  FIRST STAGE CHROOT  "; for ((n=0;n<($columns-25);n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo

  echo -e "\e[32mCreating Kali chroot.\e[0m"
  debootstrap --foreign --arch $architecture kali $kalirootfs http://http.kali.org/kali
  cp /usr/bin/qemu-arm-static $kalirootfs/usr/bin/
}

nhb_stage2(){
  export columns=$(tput cols)
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  echo -e -n "\e[31m###\e[0m  SECOND STAGE CHROOT  "; for ((n=0;n<($columns-26);n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo

  echo -e "\e[32mFinish configuring chroot.\e[0m"
  LANG=C chroot $kalirootfs /debootstrap/debootstrap --second-stage

  echo -e "\e[32mCopying sources.list.\e[0m"
  ### Copies apt-get sources file to chroot
  cp -rf $maindir/files/config/sources.list $kalirootfs/etc/apt/sources.list

  echo -e "\e[32mCopying hostname.\e[0m"
  ### Define hostname
  cp -rf $maindir/files/config/hostname $kalirootfs/etc/hostname

  echo -e "\e[32mCopying .bash_profile.\e[0m"
  ### Set up ~/.bash_profile
  cp -rf $maindir/files/config/bashprofile $kalirootfs/root/.bash_profile

  echo -e "\e[32mCopying network settings.\e[0m"
  #### Set up network settings
  cp -rf $maindir/files/config/hosts $kalirootfs/etc/hosts
  cp -rf $maindir/files/config/resolv.conf $kalirootfs/etc/resolv.conf
  cp -rf $maindir/files/config/interfaces $kalirootfs/etc/network/interfaces

  echo -e "\e[32mCopying scripts to Kali /usr/bin.\e[0m"
  #### Install Local files
  cp -rf $maindir/files/bin/s $kalirootfs/usr/bin/s
  cp -rf $maindir/files/bin/start-update.sh $kalirootfs/usr/bin/
  cp -rf $maindir/files/bin/hid/* $kalirootfs/usr/bin/
  cp -rf $maindir/files/bin/msf/*.sh $kalirootfs/usr/bin/
  chmod 755 $kalirootfs/usr/bin/*.sh
  chmod 755 $kalirootfs/usr/bin/*.py

  # Set up HID powersploit hostped payload
  mkdir -p $kalirootfs/var/www/payload
  cp -rf $maindir/files/bin/hid/powersploit-payload $kalirootfs/var/www/payload
  chmod 644 $kalirootfs/var/www/payload

  mkdir -p $rootfsdir/kali-$architecture-base
  cp -rf $kalirootfs/* $rootfsdir/kali-$architecture-base/
}

nhb_stage3(){
  export columns=$(tput cols)
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  echo -e -n "\e[31m###\e[0m  THIRD STAGE CHROOT  "; for ((n=0;n<($columns-25);n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo

  ### Packages to install to chroot
  arm="abootimg cgpt fake-hwclock ntpdate vboot-utils vboot-kernel-utils uboot-mkimage"
  base="kali-menu kali-defaults initramfs-tools usbutils openjdk-7-jre mlocate google-nexus-tools"
  desktop="kali-defaults kali-root-login desktop-base xfce4 xfce4-places-plugin xfce4-goodies"
  tools="nmap metasploit tcpdump tshark wireshark burpsuite armitage sqlmap recon-ng wipe socat ettercap-text-only beef-xss set device-pharmer"
  wireless="wifite iw aircrack-ng gpsd kismet kismet-plugins giskismet dnsmasq dsniff sslstrip mdk3 mitmproxy"
  services="autossh openssh-server tightvncserver apache2 postgresql openvpn php5"
  extras="wpasupplicant zip macchanger dbd florence libffi-dev python-setuptools python-pip hostapd ptunnel tcptrace dnsutils p0f mitmf"
  mana="python-twisted python-dnspython libnl1 libnl-dev libssl-dev sslsplit python-pcapy tinyproxy isc-dhcp-server rfkill mana-toolkit"
  bdf="backdoor-factory bdfproxy"
  spiderfoot="python-lxml python-m2crypto python-netaddr python-mako"
  sdr="sox librtlsdr"
  export packages="${arm} ${base} ${desktop} ${tools} ${wireless} ${services} ${extras} ${mana} ${spiderfoot} ${sdr} ${bdf}"

  ### Export variables
  export MALLOC_CHECK_=0
  export LC_ALL=C
  export DEBIAN_FRONTEND=noninteractive

  echo -e "\e[32mMounting partitions.\e[0m"
  ### Mount partitions
  mount -t proc proc $kalirootfs/proc
  mount -o bind /dev/ $kalirootfs/dev/
  mount -o bind /dev/pts $kalirootfs/dev/pts

  echo -e "\e[32mCreating stage-three script.\e[0m"
  ### Create third-stage script
  echo "#!/bin/bash" > $kalirootfs/third-stage
  echo "dpkg-divert --add --local --divert /usr/sbin/invoke-rc.d.chroot --rename /usr/sbin/invoke-rc.d" >> $kalirootfs/third-stage
  echo "cp /bin/true /usr/sbin/invoke-rc.d" >> $kalirootfs/third-stage
  echo "echo -e "#!/bin/sh\nexit 101" > /usr/sbin/policy-rc.d" >> $kalirootfs/third-stage
  echo "chmod +x /usr/sbin/policy-rc.d" >> $kalirootfs/third-stage
  echo "safe-apt-get update" >> $kalirootfs/third-stage
  echo "safe-apt-get install locales-all" >> $kalirootfs/third-stage
  echo "debconf-set-selections /debconf.set" >> $kalirootfs/third-stage
  echo "rm -f /debconf.set" >> $kalirootfs/third-stage
  echo "safe-apt-get update" >> $kalirootfs/third-stage
  echo "safe-apt-get -y install git-core binutils ca-certificates initramfs-tools uboot-mkimage" >> $kalirootfs/third-stage
  echo "safe-apt-get -y install locales console-common less nano git" >> $kalirootfs/third-stage
  echo "echo "root:toor" | chpasswd" >> $kalirootfs/third-stage
  echo "sed -i -e 's/KERNEL\!=\"eth\*|/KERNEL\!=\"/' /lib/udev/rules.d/75-persistent-net-generator.rules" >> $kalirootfs/third-stage
  echo "rm -f /etc/udev/rules.d/70-persistent-net.rules" >> $kalirootfs/third-stage
  echo "safe-apt-get --yes --force-yes install $packages" >> $kalirootfs/third-stage
  echo "rm -f /usr/sbin/policy-rc.d" >> $kalirootfs/third-stage
  echo "rm -f /usr/sbin/invoke-rc.d" >> $kalirootfs/third-stage
  echo "dpkg-divert --remove --rename /usr/sbin/invoke-rc.d" >> $kalirootfs/third-stage
  echo "rm -f /third-stage" >> $kalirootfs/third-stage

  ### Copy debconf.set to chroot
  cp -rf $maindir/files/config/debconf.set $kalirootfs/debconf.set

  echo -e "\e[32mExecuting stage-three script.\e[0m"
  cp -rf $maindir/files/bin/safe-apt-get $kalirootfs/usr/bin/safe-apt-get
  chmod 755 $kalirootfs/third-stage
  chmod 755 $kalirootfs/third-stage
  LANG=C chroot $kalirootfs /third-stage
}

nhb_stage4(){
  export columns=$(tput cols)
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  echo -e -n "\e[31m###\e[0m  FOURTH STAGE CHROOT  "; for ((n=0;n<($columns-26);n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo

  echo -e "\e[32mModify Kismet files.\e[0m"
  ### Modify kismet configuration to work with gpsd and socat
  sed -i 's/\# logprefix=\/some\/path\/to\/logs/logprefix=\/captures\/kismet/g' $kalirootfs/etc/kismet/kismet.conf
  sed -i 's/# ncsource=wlan0/ncsource=wlan1/g' $kalirootfs/etc/kismet/kismet.conf
  sed -i 's/gpshost=localhost:2947/gpshost=127.0.0.1:2947/g' $kalirootfs/etc/kismet/kismet.conf

  echo -e "\e[32mCopying Mana files.\e[0m"
  ### Copy over our kali specific mana config files
  cp -rf $maindir/files/bin/mana/start-mana* $kairootfs/usr/bin/
  cp -rf $maindir/files/bin/mana/stop-mana $kalirootfs/usr/bin/
  cp -rf $maindir/files/bin/mana/*.sh $kalirootfs/usr/share/mana-toolkit/run-mana/
  dos2unix $kalirootfs/usr/share/mana-toolkit/run-mana/*
  dos2unix $kalirootfs/etc/mana-toolkit/*
  chmod 755 $kalirootfs/usr/share/mana-toolkit/run-mana/*
  chmod 755 $kalirootfs/usr/bin/*.sh

  echo -e "\e[32mInstalling Rawr.\e[0m"
  ### Install Rawr (https://bitbucket.org/al14s/rawr/wiki/Usage)
  git clone https://bitbucket.org/al14s/rawr.git $kalirootfs/opt/rawr
  chmod 755 $kalirootfs/opt/rawr/install.sh

  echo -e "\e[32mCopying Wifite dictionary.\e[0m"
  ### Install Dictionary for wifite
  mkdir -p $kalirootfs/opt/dic
  tar xvf $maindir/files/dic/89.tar.gz -C $kalirootfs/opt/dic

  echo -e "\e[32mInstalling Pingen.\e[0m"
  ### Install Pingen which generates DLINK WPS pins for some routers
  wget https://raw.githubusercontent.com/devttys0/wps/master/pingens/dlink/pingen.py -O $kalirootfs/usr/bin/pingen
  chmod 755 $kalirootfs/usr/bin/pingen

  echo -e "\e[32mInstalling Spiderfoot.\e[0m"
  ### Install Spiderfoot
  LANG=C chroot $kalirootfs pip install cherrypy
  cd $kalirootfs/opt/
  wget https://github.com/smicallef/spiderfoot/archive/v2.2.0-final.tar.gz -O spiderfoot.tar.gz
  tar xvf spiderfoot.tar.gz && rm spiderfoot.tar.gz && mv spiderfoot-2.2.0-final spiderfoot
  cd $workingdir

  echo -e "\e[32mChanging Kismet log folder.\e[0m"
  ### Modify Kismet log saving folder
  sed -i 's/hs/\/captures/g' $kalirootfs/etc/kismet/kismet.conf

  echo -e "\e[32mCopying Kali menu.\e[0m"
  ### Kali Menu (bash script) to quickly launch common Android Programs
  cp -rf $maindir/files/menu/kalimenu $kalirootfs/usr/bin/kalimenu
  LANG=C chroot $kalirootfs chmod 755 /usr/bin/kalimenu
  sleep 5

  echo -e "\e[32mInstalling deADBolt.\e[0m"
  ### Installs deADBolt
  curl -o $kalirootfs/usr/bin/deadbolt https://raw.githubusercontent.com/photonicgeek/deADBolt/master/main.sh
  LANG=C chroot $kalirootfs chmod 755 /usr/bin/deadbolt

  echo -e "\e[32mInstalling APFucker.py.\e[0m"
  ### Installs APFucker.py
  curl -o $kalirootfs/usr/bin/apfucker.py https://raw.githubusercontent.com/mattoufoutu/scripts/master/AP-Fucker.py
  LANG=C chroot $kalirootfs chmod 755 /usr/bin/apfucker.py

  echo -e "\e[32mInstalling HID attack script.\e[0m"
  ### Install HID attack script and dictionaries
  cp $maindir/files/flash/system/xbin/hid-keyboard $kalirootfs/usr/bin/hid-keyboard
  cp $maindir/files/dic/pinlist.txt $kalirootfs/opt/dic/pinlist.txt
  cp $maindir/files/dic/wordlist.txt $kalirootfs/opt/dic/wordlist.txt
  cp $maindir/files/bin/hid/hid-dic.sh $kalirootfs/usr/bin/hid-dic
  LANG=C chroot $kalirootfs chmod 755 /usr/bin/hid-keyboard
  LANG=C chroot $kalirootfs chmod 755 /usr/bin/hid-dic

  ### Sets the default for hostapd.conf to the mana karma version
  sed -i 's#^DAEMON_CONF=.*#DAEMON_CONF=/etc/mana-toolkit/hostapd-karma.conf#' $kalirootfs/etc/init.d/hostapd
  sed -i 's/wlan0/wlan1/g' $kalirootfs/etc/mana-toolkit/hostapd-karma.conf

  echo -e "\e[32mCopying DNSMasq.conf.\e[0m"
  ### DNSMASQ Configuration options for optional access point
  cp -rf $maindir/files/config/dnsmasq.conf $kalirootfs/etc/dnsmasq.conf

  echo -e "\e[32mCreating extra directories for NetHunter.\e[0m"
  ### Add missing folders to chroot needed
  cap=$kalirootfs/captures
  mkdir -p $kalirootfs/root/.ssh/
  mkdir -p $kalirootfs/sdcard $kalirootfs/system
  mkdir -p $cap/evilap $cap/ettercap $cap/kismet/db $cap/nmap $cap/sslstrip $cap/tshark $cap/wifite $cap/tcpdump $cap/urlsnarf $cap/dsniff $cap/honeyproxy $cap/mana/sslsplit

  echo -e "\e[32mConfiguring Beef-xss.\e[0m"
  ### In order for metasploit to work daemon,nginx,postgres must all be added to inet
  ### beef-xss creates user beef-xss. Openvpn server requires nobdy:nobody in order to work
  echo "inet:x:3004:postgres,root,beef-xss,daemon,nginx" >> $kalirootfs/etc/group
  echo "nobody:x:3004:nobody" >> $kalirootfs/etc/group
}

nhb_clean(){
  export columns=$(tput cols)
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  echo -e -n "\e[31m###\e[0m  CLEAN UP CHROOT  "; for ((n=0;n<($columns-22);n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo

  echo -e "\e[32mRunning clean-up script.\e[0m"
  ### Run clean-up script
  cp -rf $maindir/files/config/cleanup $kalirootfs/cleanup
  chmod +x $kalirootfs/cleanup
  LANG=C chroot $kalirootfs /cleanup
  sleep 5

  echo -e "\e[32mUnmounting partitions.\e[0m"
  ### Unmount partitions
  sleep 10
  umount $kalirootfs/dev/pts
  umount $kalirootfs/dev/
  umount -lf $kalirootfs/proc
}

nhb_compress(){
  export columns=$(tput cols)
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  echo -e -n "\e[31m###\e[0m  COMPRESSING KALI FS  "; for ((n=0;n<($columns-26);n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo

  echo -e "\e[32mCleaning /dev directory.\e[0m"
  ### Clean up chrooted /dev before packaging.
  rm -rf  $kalirootfs/dev/*

  ### Compress filesystem and add to zip
  cd $kalirootfs
  echo -e "\e[32mCompressing kali rootfs into working directory. Please wait.\e[0m"
  tar jcf $rootfsdir/kalifs.tar.bz2 $kalirootfs
}

nhb_zip(){
  export columns=$(tput cols)
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  echo -e -n "\e[31m###\e[0m  CREATING ZIP  "; for ((n=0;n<($columns-19);n++)); do echo -e -n "\e[31m#\e[0m"; done; echo
  for ((n=0;n<$columns;n++)); do echo -e -n "\e[31m#\e[0m"; done; echo

  echo -e "\e[32mCopying premade flashable directory.\e[0m"
  ### Create base flashable zip
  cp -rf $maindir/files/flash $workingdir/
  mkdir -p $workingdir/flash/data/local/
  mkdir -p $workingdir/flash/system/lib/modules

  echo -e "\e[32mCopying rootfs to flash directory.\e[0m"
  cp $rootfsdir/kalifs.tar.bz2 $workingdir/flash/data/local/kalifs.tar.bz2

  echo -e "\e[32mInstalling extra applications for Android.\e[0m"
  ### Download/add Android applications that are useful to our chroot enviornment
  ### Required: Terminal application is required
  wget -P $workingdir/flash/data/app/ http://jackpal.github.com/Android-Terminal-Emulator/downloads/Term.apk
  ### Suggested: BlueNMEA to enable GPS logging in Kismet
  wget -P $workingdir/flash/data/app/ http://max.kellermann.name/download/blue-nmea/BlueNMEA-2.1.3.apk
  ### Suggested: Hackers Keyboard for easier typing in the terminal
  wget -P $workingdir/flash/data/app/ https://hackerskeyboard.googlecode.com/files/hackerskeyboard-v1037.apk
  ### Suggested: Android VNC Viewer
  wget -P $workingdir/flash/data/app/ https://android-vnc-viewer.googlecode.com/files/androidVNC_build20110327.apk
  ### Suggested: DriveDroid for CDROM emulation
  wget -P $workingdir/flash/data/app/ http://softwarebakery.com/apps/drivedroid/files/drivedroid-free-0.9.17.apk
  ### Keyboard HID app
  wget -P $workingdir/flash/data/app/ https://github.com/pelya/android-keyboard-gadget/raw/master/USB-Keyboard.apk
  ### Suggested: RFAnalyzer
  wget -P $workingdir/flash/data/app/ https://github.com/demantz/RFAnalyzer/raw/master/RFAnalyzer.apk
  echo -e "\e[32mStructure for flashable zip file is complete.\e[0m"

  echo -e "\e[32mCreating flashable zip.\e[0m"
  cd $workingdir/flash/
  zip -r6 NetHunter-$date.zip *
  mv NetHunter-$date.zip $workingdir
  cd $workingdir
  # Generate sha1sum
  echo -e "\e[32mGenerating sha1sum for NetHunter-$date.zip.\e[0m"
  sha1sum NetHunter-$date.zip > $workingdir/NetHunter-$date.sha1sum
  sleep 5
}

if [[ -d $rootfsdir/kali-$architecture-base ]]; then
  mkdir -p $kalirootfs
  cp -rf $rootfsdir/kali-$architecture-base/* $kalirootfs/

  nhb_stage3
  nhb_stage4
  nhb_clean
  nhb_compress
  nhb_zip
else
  nhb_setup
  nhb_stage1
  nhb_stage2
  nhb_stage3
  nhb_stage4
  nhb_clean
  nhb_compress
  nhb_zip
fi
rm -rf $kalirootfs
