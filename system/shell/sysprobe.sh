# sysprobe.sh - System Probe Script
# Copyright (C) 2023 Justin Carver
#
# This script is intended to be Linux Distro Agnostic.
# Gathers vast swathes of information on a running system.
# Useful for quick data dumps on core running processes.
#
# Usage:
#       chmod +x sysprobe.sh
#       ./sysprobe.sh output.log
#
# If no argument is provided, the output will be printed to the console.

#!/bin/bash

# Define color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command exists
function check_command {
    command -v $1 >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}The command $1 is not available on this system.${NC}"
    else
        $1 "${@:2}"
    fi
}

# Checking if the output file flag is set
if [ $# -eq 0 ]
then
    OUTPUT=/dev/stdout
else
    OUTPUT=$1
fi

{

current_time=$(date +%Y-%m-%d_%H:%M:%S)

echo -e "${GREEN}Performing initial distro analysis...${NC}"
echo -e "${YELLOW}Time of script run: $current_time${NC}"
echo -e "${YELLOW}Logging to: $(pwd)/$1${NC}"

echo -e "\n${RED}-------------------------------${NC}"

# Reporting basic information about a computer's software and hardware
echo -e "${YELLOW}\nSystem Information:${NC}"
check_command uname -a
check_command hostnamectl
check_command cat /etc/*release*

# Displaying the total amount of free and used physical and swap memory
echo -e "${YELLOW}\nMemory Information:${NC}"
check_command free -h

# Displaying the system load averages
echo -e "${YELLOW}\nSystem Load Averages:${NC}"
check_command uptime

echo -e "\n${RED}-------------------------------${NC}"

# Reporting the amount of disk space used and available
echo -e "${YELLOW}\nDisk Usage:${NC}"
check_command df -hT

# Listing information about all available block devices
echo -e "${YELLOW}\nBlock Device Information:${NC}"
check_command lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT

echo -e "\n${RED}-------------------------------${NC}"

# Displaying information about the CPU architecture
echo -e "${YELLOW}\nCPU Information:${NC}"
check_command lscpu

# Doing some simple drive performance tests
echo -e "${YELLOW}\nDisk Performance:${NC}"
check_command hdparm -Tt $(lsblk -d | awk '{print $1}' | sed -n 2p) # Dynamically getting the disk to test

echo -e "\n${RED}-------------------------------${NC}"

# Reporting information about processes, memory, paging, block IO, traps, and cpu activity
echo -e "${YELLOW}\nVMStat:${NC}"
check_command vmstat -w

echo -e "\n${RED}-------------------------------${NC}"

echo -e "${YELLOW}\nTop 5 Processes (mem):${NC}"
check_command ps -aux --sort=-%mem | head -n 5

echo -e "\n"
echo -e "${YELLOW}\nTop 5 Processes (cpu):${NC}"
check_command ps -aux --sort=-%cpu | head -n 5

echo -e "\n${RED}-------------------------------${NC}"

# Network Statistics
echo -e "${YELLOW}\nNetwork Statistics:${NC}"
check_command ss -s
check_command ip a

# Display Iptables Rules
echo -e "${YELLOW}\nIptables Rules:${NC}"
check_command iptables -L -v -n

# Open Ports
echo -e "${YELLOW}\nOpen Ports:${NC}"
check_command ss -tuln

# Check Kernel Messages
echo -e "${YELLOW}\nKernel Messages:${NC}"
check_command dmesg | tail

echo -e "\n${RED}-------------------------------${NC}"

# List of Failed Services
echo -e "${YELLOW}\nFailed Systemd Services:${NC}"
check_command systemctl --failed

# Scheduled Cron Jobs
echo -e "${YELLOW}\nSystem-wide Cron Jobs:${NC}"
check_command cat /etc/crontab

# Current User's Crontab
echo -e "${YELLOW}\nCurrent User's Crontab:${NC}"
check_command crontab -l

echo -e "\n${RED}-------------------------------${NC}"

# List of Installed Packages
echo -e "${YELLOW}\nInstalled Packages (Debian/Ubuntu):${NC}"
check_command dpkg -l

echo -e "${YELLOW}\nInstalled Packages (Fedora/CentOS/RHEL):${NC}"
check_command rpm -qa

# Display Kernel Parameters
echo -e "${YELLOW}\nKernel Parameters:${NC}"
check_command sysctl -a | egrep "vm.swappiness|vm.vfs_cache_pressure|kernel.pid_max|fs.file-max"

# Display User Environment Variables
echo -e "${YELLOW}\nUser Environment Variables:${NC}"
check_command printenv

# Show Systemd Timers
echo -e "${YELLOW}\nSystemd Timers:${NC}"
check_command systemctl list-timers --all

# Display Security Updates
echo -e "${YELLOW}\nSecurity Updates (Debian/Ubuntu):${NC}"
check_command apt list --upgradable 2>/dev/null | grep "/security"

echo -e "${YELLOW}\nSecurity Updates (Fedora/CentOS/RHEL):${NC}"
check_command yum updateinfo list sec 2>/dev/null

# Show Firewall Status
echo -e "${YELLOW}\nFirewall Status:${NC}"
check_command ufw status verbose

# Display SSH Configuration
echo -e "${YELLOW}\nSSH Configuration:${NC}"
check_command cat /etc/ssh/sshd_config

# Display User History
echo -e "${YELLOW}\nUser History:${NC}"
check_command history

# Check for Core Dumps
echo -e "${YELLOW}\nCore Dumps:${NC}"
check_command ls /var/crash/

# List System Services
echo -e "${YELLOW}\nSystem Services:${NC}"
check_command systemctl list-units --type=service

} | tee $OUTPUT