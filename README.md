# Kali Linux NetHunter for Nexus Devices
========================================
Kali Linux NetHunter is a Android penetration testing platform for Nexus devices built on top of Kali Linux, which includes some special and unique features. Of course, you have all the usual Kali tools in NetHunter as well as the ability to get a full VNC session from your phone to a graphical Kali chroot, however the strength of NetHunter does not end there.
We've incorporated some amazing features into the NetHunter OS which are both powerful and unique. From pre-programmed HID Keyboard (Teensy) attacks, to BadUSB Man In The Middle attacks, to one-click MANA Evil Access Point setups. And yes, NetHunter natively supports wireless 802.11 frame injection with a variety of supported USB NICs. NetHunter is still in its infancy and we are looking forward to seeing this project and community grow.

## Nethunter Android Application

If you wish to submit changes or have issues with the Nethunter Android Application, please see the github repo here: [https://github.com/offensive-security/nethunter-app] (https://github.com/offensive-security/nethunter-app).

## Installation Instructions
Installation instructions and image downloads can be found at [nethunter.com](http://nethunter.com).

## Building from sources
You can also rebuild the NetHunter images from scratch, which allows for easier image modification. For best results use a 64 bit Kali Linux development environment with over 10Gb free disk space and enter the following commands:

```
curl -o firstrun.sh 'https://raw.githubusercontent.com/offensive-security/kali-nethunter/nethunterbuild/scripts/firstrun.sh'
chmod +x ./firstrun.sh
./firstrun.sh
```
