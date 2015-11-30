#!/bin/sh

# Install packages
pacman -S --noconfirm net-tools wpa_supplicant



#echo "Would you use DHCP"
#select yn in "Yes" "No"; do
#    case $yn in
#        Yes ) 	pacman -S --noconfirm docker
#		systemctl enable docker
#		systemctl start docker; break;;
#       No ) exit;;
#    esac
#done

### SCRIPT VARIABLES
## Ask user for system specific variables
read -p 'Enter the WiFI device name, like wlan0: ' networkDeviceWlan
read -p 'Enter IP address, like 192.168.0.101: ' networkIpWlan
read -p 'Enter Subnet, like 24: ' networkSubnet
read -p 'Enter Gateway: ' networkGateway
read -p 'Enter DNS1: ' networkDns1
read -p 'Enter DNS2: ' networkDns2
#read -p 'Enter DNS Search Domain: ' networkDnsSearch

# Network variables
#networkDeviceWlan=wlan0
#networkSubnetWlan=24
#networkGatewayWlan=10.10.40.254
#common network settings
#networkDns1=10.10.100.100
#networkDns2=10.10.100.110
#networkDnsSearch=domain.local


# System Variables
#systemRootPassword=Emmel00rd
systemNtp0=0.nl.pool.ntp.org
systemNtp1=1.nl.pool.ntp.org
systemNtp2=2.nl.pool.ntp.org
systemNtp3=3.nl.pool.ntp.org

#############################################################


##	Configure networking

# Configure networking on wlan0 with a static IP:
echo -e "Description='Network - $networkDeviceWlan'\nInterface=$networkDeviceWlan\nConnection=wireless\nIP=static\nAddress=('$networkIpWlan/$networkSubnetWlan')\nGateway=('$networkGatewayWlan')\nDNS=('$networkDns1' '$networkDns2')\nSecurity='wpa'\nESSID='Wi-Fi Network'\nKey='Emmel00rd'" > /etc/netctl/wlan0


# Enable the new interface's so it starts the next time the system boots:
netctl enable $networkDeviceWlan

# Install packages
#pacman -S --noconfirm wget nano vi net-tools iftop iotop tar zip wpa_supplicant



#echo "Would you like to install Docker on this system?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) 	pacman -S --noconfirm docker
		systemctl enable docker
		systemctl start docker; break;;
       No ) exit;;
    esac
done

# Update Arch Linux:
# pacman --noconfirm -Syu

# Ask user to reboot the system, if true then reboot system:
echo "The system has been updated and needs to be rebooted, do you want to reboot right now?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) reboot; break;;
        No ) exit;;
    esac
done

# Shutdown system
shutdown -r now
