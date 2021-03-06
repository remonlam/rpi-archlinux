#!/bin/sh

########################## INFO ##########################
# SOURCE: https://github.com/remonlam/rpi-archlinux

########################## RUNTIME CHECK ##########################
# Check if script is running as root, if not then exit
  echo "THIS SCRIPT NEEDS TO BE RUN AS ROOT, CHECKING..."
    if [ `id -u` = 0 ] ; then
          echo "Running as ROOT, continue with script..."
    else
          echo "Not running as ROOT exit script..."
          exit 1
fi



########################## SCRIPT VARIABLES ##########################
## Ask user for system specific variables
echo "NOTE: PI 1 MODEL A+, PI 1 MODEL B+, PI ZERO are 6 --- PI 2 MODEL B is 7"
read -p 'What version of Pi? 6 or 7 ' armVersion
read -p 'Enter device name (SD-Card): like sdb: ' sdCard
read -p 'Enter a new hostname: ' hostName
read -p 'Enter network adapter (eth0): ' networkDevice
##read -p 'Enter wifi name (Accesspoint): ' wifiAP ## USED FOR WLAN
##read -p 'Enter wifi password: ' wifiKey ## USED FOR WLAN
read -p 'Enter IP address: ' networkIp
read -p 'Enter Subnet: ' networkSubnet
read -p 'Enter Gateway: ' networkGateway
read -p 'Enter DNS1: ' networkDns1
read -p 'Enter DNS2: ' networkDns2
read -p 'Enter DNS Search Domain: ' networkDnsSearch

# Partition VARIABLES
part1=1
part2=2

# Time services VARIABLES
# Note: this will make you use the Dutch time server, chekc ntp.org for your local ntp pool
systemNtp0=0.nl.pool.ntp.org
systemNtp1=1.nl.pool.ntp.org
systemNtp2=2.nl.pool.ntp.org
systemNtp3=3.nl.pool.ntp.org



########################## PRE-REQUIREMENTS ##########################
# Check or install wget, tar and badtar
  yum install -y wget bsdtar tar

# Wipe microSD card @ $sdCard
  echo "Wipe microSD card ('$sdCard')"
  dd if=/dev/zero of=/dev/$sdCard bs=1M count=1



########################## SD CARD PREPARATION ##########################

### CREATE NEW PARTITION:
  # Create parition layout
  echo "Create new parition layout on '$sdCard'"
  # NOTE: This will create a partition layout as beeing described in the README...
  (echo o; echo n; echo p; echo 1; echo ; echo +100M; echo t; echo c; echo n; echo p; echo 2; echo ; echo ; echo w) | fdisk /dev/$sdCard

  # Sync disk
  sync

### CREATE AND MOUNT FAT FS:
  echo "Create and mount the FAT filesystem on '$sdCard$part1'"
  mkfs.vfat /dev/$sdCard$part1
  mkdir -p /temp/boot
  mount /dev/$sdCard$part1 /temp/boot

### CREATE AND MOUNT EXT4 FS:
echo "Create and mount the ext4 filesystem on '$sdCard$part2'"
mkfs.ext4 /dev/$sdCard$part2
mkdir -p /temp/root
mount /dev/$sdCard$part2 /temp/root




########################## DOWNLOAD ARCH LINUX IMAGE ##########################

### DOWNLAOD CORRECT IMAGE FOR ARM ARCHITECTURE:
  # Download Arch Linux ARM image, check what version ARM v6 or v7
  echo "Download Arch Linux ARM v'$armVersion' and expand to root"
  if [ $armVersion -eq 6 ]
  then
      echo "Downloading Arch Linux ARM v'$armVersion'"
        wget -P /temp/ http://archlinuxarm.org/os/ArchLinuxARM-rpi-latest.tar.gz
      echo "Download complete, expanding tar.gz to root"
        bsdtar -xpf /temp/ArchLinuxARM-rpi-latest.tar.gz -C /temp/root
      sync
    else
      echo "Downloading Arch Linux ARM v'$armVersion'"
        wget  -P /temp/ http://archlinuxarm.org/os/ArchLinuxARM-rpi-2-latest.tar.gz
      echo "Download complete, expanding tar.gz to root"
        bsdtar -xpf /temp/ArchLinuxARM-rpi-2-latest.tar.gz -C /temp/root
      sync
    fi
    echo "Download and extract complete"

### COPY IMAGE FILES TO CORRECT PARTITION:
  # Move boot files to the first partition:
    mv /temp/root/boot/* /temp/boot
    echo '# Change rotation of Pi Screen' >> /temp/boot/config.txt
    echo lcd_rotate=2 >> /temp/boot/config.txt


### MAKE CHANGES IN BOOT CONFIG:
  # Change GPU memory from 64MB to 16MB
    sed -i 's/gpu_mem=64/gpu_mem=16/' /temp/boot/config.txt



########################## NETWORKING ##########################

### NETCTL ETH0 CONFIGURATION:
  # Copy netctl eth0 config file
  wget -P /temp/ https://raw.githubusercontent.com/remonlam/rpi-archlinux/master/systemd_config/eth0

  # Injecting network information to the eth0 config file
  echo -e "Description='Network - $networkDevice'\nInterface=$networkDevice\nConnection=ethernet\nIP=static\nAddress=('$networkIp/$networkSubnet')\nGateway=('$networkGateway')\nDNS=('$networkDns1' '$networkDns2')" > /temp/eth0

  # Copy eth0 config file to SD card
  cp -rf /temp/eth0 /temp/root/etc/netctl/


### SYSTEMD ETH0.SERVICE CONFIGURATION:
  # Copy eth0.service file to systemd and create symlink to make it work at first boot
  wget -P /temp/ https://raw.githubusercontent.com/remonlam/rpi-archlinux/master/systemd_config/netctl%40eth0.service

  # Copy netctl@eth0 config file to SD card
  cp -rf /temp/netctl@eth0.service /temp/root/etc/systemd/system/

  # Create symlink
ln -s '/temp/root/etc/systemd/system/netctl@eth0.service' '/temp/root/etc/systemd/system/multi-user.target.wants/netctl@eth0.service'


### POPULATE DNS CONFIGURATION:

  # Remove symlink to resolv.conf
  rm -rf /temp/root/etc/resolv.conf
  # Populate /etc/resolv.conf with new dns servers:
  echo -e "search $networkDnsSearch\nnameserver $networkDns1\nnameserver $networkDns2" > /temp/root/etc/resolv.conf


### CLEANUP SYSTEMD NETWORKING AND RESOLVING:

  # Cleanup Systemd NETWORKING
  rm -rf /temp/root/etc/systemd/system/multi-user.target.wants/systemd-networkd.service
  rm -rf /temp/root/etc/systemd/system/sockets.target.wants/systemd-networkd.socket

  # Cleanup Systemd RESOLVING
  rm -rf /temp/root/etc/systemd/system/multi-user.target.wants/systemd-resolved.service



########################## SYSTEM CONFIGURATION ##########################

### TIME SETTINGS:
  # Time zone configuration, sets it to Europe/Amsterdam:
  #timedatectl set-timezone Europe/Amsterdam

  # Populate NTP source file "etc/systemd/timesyncd.conf":
  echo -e "NTP=$systemNtp0 $systemNtp1 $systemNtp2 $systemNtp3" > /temp/root/etc/systemd/timesyncd.conf

### SSH CONFIGURATION:
  # Enable root logins for sshd
  sed -i "s/"#"PermitRootLogin prohibit-password/PermitRootLogin yes/" /temp/root/etc/ssh/sshd_config

  # Change hostname
  sed -i 's/alarmpi/'$hostName'/' /temp/root/etc/hostname



########################## FINALIZING SD CARD POPULATION ##########################

### SYNC CHANGES TO DISK:
  # Do a final sync, and wait 5 seconds before unmouting
  sync
  echo "Wait 5 seconds before unmouting 'boot' and 'root' mount points"
  sleep 5


### UNMOUNT AND CLEANUP TEMP FILES:
  # Unmount the boot and root partitions:
  umount /temp/boot /temp/root
  echo "Unmount completed, it's safe to remove the microSD card!"

  # Removing data sources
  echo "Remove datasources, waiting until mount points are removed"
  sleep 5
  rm -rf /temp/
  echo "All files in /temp/ are removed!"

  # Set exit code to zero
  exit 0
  echo "You can login with the following accounts;"
  echo "USER: arch pw=arch"
  echo "ROOT: root pw=root"
  echo ""
  echo "You can now safely remove the SD-Card"
