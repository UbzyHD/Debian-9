#!/bin/bash

##################################################
#               Script Description               #
##################################################
#      This script will automatically setup      #
#          a virtualised Debian 9 server         #
#        freshly installed out of the box        #
##################################################

#######################################
#              How To Use             #
#######################################
#       Login to root account or      #
#    run "su -" on a normal account   #
#        run the following line       #
# wget https://raw.githubusercontent.com/UbzyHD/Debian-9-Scripts/master/Debian-9-First.sh; chmod +x Debian-9-First.sh; ./Debian-9-First.sh; #
#######################################

#######################################
#     Colour Codes (do not change)    #
#######################################
GREEN="\033[1;32m"                    #
GREENBLINK="\033[32;5;7m"             #
NOCOLOR="\033[0m"                     #
#######################################

####################################
#   User Variables (change these)  #
####################################
USER=ubaidulislam                  ##
####################################

echo -e "${GREEN}Installing Sudo"
apt install sudo -y &> /dev/null

echo -e "${GREEN}Adding $USER to Sudo group"
usermod -aG sudo $USER

echo -e "${GREEN}Updating Server"
sudo -- sh -c 'apt update; apt upgrade -y; apt dist-upgrade -y; apt autoremove -y; apt autoclean -y' &> /dev/null

echo -e "${GREEN}Installing Open-VM-Tools"
sudo apt install open-vm-tools -y &> /dev/null

echo -e "Changing GRUB Timeout"
File=/etc/default/grub
sudo sed -i "/GRUB_TIMEOUT=5/c GRUB_TIMEOUT=1" /etc/default/grub
if grep -q 'GRUB_TIMEOUT=1' "$File";
then
echo -e "${GREEN}GRUB_TIMEOUT=1 set in GRUB${NOCOLOR}"
else
echo -e "${GREEN}Setting GRUB Timeout Failed${NOCOLOR}"
fi

echo -e "${GREEN}Updating GRUB Changes${NOCOLOR}"
update-grub &> /dev/null

echo -e "${GREEN}Modifying Sysctl"
tee << 'EOF' >> /etc/sysctl.conf
# Disable IPv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Kernel Hardening
kernel.sysrq = 0
kernel.kptr_restrict = 2
kernel.core_uses_pid = 1
kernel.yama.ptrace_scope = 3

# Disable Timestaps
net.ipv4.tcp_timestamps = 0

# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Block SYN attacks
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Log Martians
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.default.log_martians = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
EOF
sudo sysctl -p
sudo sysctl --system
sudo service procps reload

echo -e "${GREEN}Updating Server"
sudo -- sh -c 'apt update; apt upgrade -y; apt dist-upgrade -y; apt autoremove -y; apt autoclean -y' &> /dev/null

echo -e "${GREEN}Configuring Unnattended Upgrades"
sudo apt install unattended-upgrades -y &> /dev/null
echo 'Unattended-Upgrade::Remove-Unused-Dependencies "true";' >> /etc/apt/apt.conf.d/50unattended-upgrades &> /dev/null
echo 'Unattended-Upgrade::MailOnlyOnError "true";' >> /etc/apt/apt.conf.d/50unattended-upgrades &> /dev/null
echo 'Unattended-Upgrade::Automatic-Reboot "true";' >> /etc/apt/apt.conf.d/50unattended-upgrades &> /dev/null
echo 'Unattended-Upgrade::Automatic-Reboot-Time "03:00";' >> /etc/apt/apt.conf.d/50unattended-upgrades &> /dev/null

echo -e "${GREENBLINK}Rebooting Server!${NOCOLOR}"
sudo reboot
