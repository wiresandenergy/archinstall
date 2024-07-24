#!/bin/bash

echo 'figlet $(hostname)
printf "\n"

printf "Welcome to %s (%s).\n" "$DISTRIB_DESCRIPTION" "$(uname -r)"
printf "\n"

neofetch

printf "\n"

date=`date`
load=`cat /proc/loadavg | awk '{print $1}'`
root_usage=`df -h / | awk '/\// {print $(NF-1)}'`
memory_usage=`free -m | awk '/Mem:/ { total=$2; used=$3 } END { printf("%3.1f%%", used/total*100)}'`

swap_usage=`free -m | awk '/Swap/ { printf("%3.1f%%", $3/$2*100) }'`
users=`users | wc -w`
time=`uptime | grep -ohe 'up .*' | sed 's/,/\ hours/g' | awk '{ printf $2" "$3 }'`
processes=`ps aux | wc -l`
ip=`ip -o -4 addr list eno1 | awk '{print $4}' | cut -d/ -f1`

echo "System information as of: $date"
echo
printf "System Load:\t%s\tIP Address:\t%s\n" $load $ip
printf "Memory Usage:\t%s\tSystem Uptime:\t%s\n" $memory_usage "$time"
printf "Usage On /:\t%s\tSwap Usage:\t%s\n" $root_usage $swap_usage
printf "Local Users:\t%s\tProcesses:\t%s\n" $users $processes
echo' >> /etc/profile.d/motd.sh
