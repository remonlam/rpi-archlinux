#Create an ArchLinux ARM (Raspberry Pi) SD Card image.
![Raspberry Pi, ArchLinux & Docker](/images/pi-archlinux+docker.png)

For some reason ArchLinux community stop providing an pre-build image for the Raspberry Pi.
The instructions bellow are straight form there website @ (http://archlinuxarm.org/platforms/armv7/broadcom/raspberry-pi-2).

To make things simple I've created a little script to automate some of the steps.
It's been tested on CentOS 7 but it could run on other Linux systems as well.

And if you're really lazy you could also use the .IMG file that can be found over here.

##SD Card Creation
Replace sdX in the following instructions with the device name for the SD card as it appears on your computer.

####Start fdisk to partition the SD card:
fdisk /dev/sdX
At the fdisk prompt, delete old partitions and create a new one:
Type o. This will clear out any partitions on the drive.
Type p to list partitions. There should be no partitions left.
Type n, then p for primary, 1 for the first partition on the drive, press ENTER to accept the default first sector, then type +100M for the last sector.
Type t, then c to set the first partition to type W95 FAT32 (LBA).
Type n, then p for primary, 2 for the second partition on the drive, and then press ENTER twice to accept the default first and last sector.
Write the partition table and exit by typing w.

####Create and mount the FAT filesystem:
mkfs.vfat /dev/sdX1
mkdir boot
mount /dev/sdX1 boot

####Create and mount the ext4 filesystem:
mkfs.ext4 /dev/sdX2
mkdir root
mount /dev/sdX2 root

####Download and extract the root filesystem (as root, not via sudo):
wget http://archlinuxarm.org/os/ArchLinuxARM-rpi-2-latest.tar.gz
bsdtar -xpf ArchLinuxARM-rpi-2-latest.tar.gz -C root
sync

####Move boot files to the first partition:
mv root/boot/* boot
Unmount the two partitions:
umount boot root

###Insert the SD card into the Raspberry Pi, connect ethernet, and apply 5V power.
Use the serial console or SSH to the IP address given to the board by your router.
Login as the default user alarm with the password alarm.
The default root password is root.
