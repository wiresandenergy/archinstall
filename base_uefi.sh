#!/bin/bash

ln -sf /usr/share/zoneinfo/America/Denver /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "arch" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 arch.gordonia.net arch" >> /etc/hosts
echo root:password | chpasswd

# You can add xorg to the installation packages, I usually add it at the DE or WM install script
# You can remove the tlp package if you are installing on a desktop or vm

pacman -S grub efibootmgr mtools dosfstools git avahi networkmanager dialog sddm acpid network-manager-applet xdg-user-dirs xdg-utils wpa_supplicant cups reflector inetutils base-devel linux-headers linux-firmware zsh iotop htop ntp wget curl nmap figlet bluez bluez-utils neofetch fuse sudo parted alsa-utils alsa-tools pipewire pipewire-alsa pipewire-pulse pipewire-jack openssh acpi acpi_call flatpak gdisk python3 samba nfs-utils python-pip dnsutils tree openssh bash-completion terminus-font rsync btrfs-progs docker docker-compose net-tools lsof lshw firewalld fail2ban pacman-contrib man gvfs gvfs-smb hplip tlp virt-manager qemu edk2-ovmf bridge-utils dnsmasq vde2 openbsd-netcat iptables-nft ipset sof-firmware nss-mdns os-prober ntfs-3g plasma tk pyenv libreoffice-fresh  --needed

# pacman -S --noconfirm xf86-video-amdgpu
# pacman -S --noconfirm nvidia nvidia-utils nvidia-settings

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB #change the directory to /boot/efi is you mounted the EFI partition at /boot/efi

grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable avahi-daemon
systemctl enable tlp # You can comment this command out if you didn't install tlp, see above
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable libvirtd
systemctl enable firewalld
systemctl enable acpid

useradd -m wiresandenergy
echo wiresandenergy:password | chpasswd
usermod -aG libvirt,power,audio,wheel,storage,flatpak,kvm wiresandenergy

echo "wiresandenergy ALL=(ALL) ALL" >> /etc/sudoers.d/wiresandenergy

echo "export EDITOR=nvim" >> ~/.bashrc
source ~/.bashrc

cat <<'END_CAT' > /etc/profile.d/motd.sh
if [ -z "$DISTRIB_DESCRIPTION" ] ; [ -x /usr/bin/lsb_release ]; then
        # Fall back to using the very slow lsb_release utility
        DISTRIB_DESCRIPTION=$(lsb_release -s -d)
fi

figlet $(hostname)
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
ip=`ip -o -4 addr list ens18 | awk '{print $4}' | cut -d/ -f1`

echo "System information as of: $date"
echo
printf "System Load:\t%s\tIP Address:\t%s\n" $load $ip
printf "Memory Usage:\t%s\tSystem Uptime:\t%s\n" $memory_usage "$time"
printf "Usage On /:\t%s\tSwap Usage:\t%s\n" $root_usage $swap_usage
printf "Local Users:\t%s\tProcesses:\t%s\n" $users $processes
echo
END_CAT

cp /etc/xdg/reflector/reflector.conf{,.bak}

cat <<'END_CAT' > /etc/xdg/reflector/reflector.conf
--save /etc/pacman.d/mirrorlist
--country "United States"
--protocol https
--latest 10
--sort rate"
END_CAT

systemctl enable reflector

pacman -S git base-devel --needed

cd /home/wiresandenergy/

git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
su wiresandenergy -c 'makepkg -si'

su wiresandenergy -c 'yay -S apache-tools wsdd update-grub timeshift timeshift-autosnap --noconfirm'

sudo systemctl enable --now wsdd

printf "\e[1;32mDone! Type exit, umount -a and reboot.\e[0m"
