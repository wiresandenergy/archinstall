#!/bin/bash

ln -sf /usr/share/zoneinfo/America/Denver /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=us" >> /etc/vconsole.conf
echo "arch" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 arch.gordonia.net arch" >> /etc/hosts

echo "Enter desired password: "
read install_pass

echo root:$install_pass | chpasswd

# You can add xorg to the installation packages, I usually add it at the DE or WM install script
# You can remove the tlp package if you are installing on a desktop or vm

sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10 \nILoveCandy/' /etc/pacman.conf
sed -i 's/#\[multilib]/\[multilib]\nInclude = \/etc\/pacman.d\/mirrorlist/' /etc/pacman.conf

pacman -Syyu --noconfirm

pacman -S grub efibootmgr mtools dosfstools git avahi networkmanager dialog sddm acpid network-manager-applet xdg-user-dirs xdg-utils wpa_supplicant cups reflector inetutils base-devel linux-headers linux-firmware zsh iotop htop ntp wget curl nmap figlet bluez bluez-utils neofetch fuse sudo parted alsa-utils alsa-tools pipewire pipewire-alsa pipewire-pulse pipewire-jack openssh acpi acpi_call flatpak gdisk python3 samba nfs-utils python-pip dnsutils tree openssh bash-completion terminus-font rsync btrfs-progs docker docker-compose net-tools lsof lshw firewalld fail2ban pacman-contrib man gvfs gvfs-smb hplip tlp virt-manager qemu edk2-ovmf bridge-utils dnsmasq vde2 openbsd-netcat iptables-nft ipset sof-firmware nss-mdns os-prober ntfs-3g plasma tk pyenv libreoffice-fresh kate konsole kitty thunar catfish gvfs tumbler thunar-volman thunar-archive-plugin thunar-media-tags-plugin neovim firefox --needed

# pacman -S --noconfirm xf86-video-amdgpu
# pacman -S --noconfirm nvidia nvidia-utils nvidia-settings

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB #change the directory to /boot/efi is you mounted the EFI partition at /boot/efi

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
systemctl enable sddm
systemctl enable docker

useradd -m wiresandenergy
echo wiresandenergy:$install_pass | chpasswd

echo "wiresandenergy ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers.d/wiresandenergy

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

cat <<'END_CAT' > /etc/samba/smb.conf
# This is the main Samba configuration file. You should read the
# smb.conf(5) manual page in order to understand the options listed
# here. Samba has a huge number of configurable options (perhaps too
# many!) most of which are not shown in this example
#
# For a step to step guide on installing, configuring and using samba,
# read the Samba-HOWTO-Collection. This may be obtained from:
#  http://www.samba.org/samba/docs/Samba-HOWTO-Collection.pdf
#
# Many working examples of smb.conf files can be found in the
# Samba-Guide which is generated daily and can be downloaded from:
#  http://www.samba.org/samba/docs/Samba-Guide.pdf
#
# Any line which starts with a ; (semi-colon) or a # (hash)
# is a comment and is ignored. In this example we will use a #
# for commentry and a ; for parts of the config file that you
# may wish to enable
#
# NOTE: Whenever you modify this file you should run the command "testparm"
# to check that you have not made any basic syntactic errors.
#
#======================= Global Settings =====================================
[global]

    map to guest = bad user
    security = user
    rpc_server:spoolss = external
    rpc_daemon:spoolssd = fork
    printing = CUPS

# workgroup = NT-Domain-Name or Workgroup-Name, eg: MIDEARTH
   workgroup = WORKGROUP

# server string is the equivalent of the NT Description field
   server string = Samba Server

# Server role. Defines in which mode Samba will operate. Possible
# values are "standalone server", "member server", "classic primary
# domain controller", "classic backup domain controller", "active
# directory domain controller".
#
# Most people will want "standalone server" or "member server".
# Running as "active directory domain controller" will require first
# running "samba-tool domain provision" to wipe databases and create a
# new domain.
   server role = standalone server

# This option is important for security. It allows you to restrict
# connections to machines which are on your local network. The
# following example restricts access to two C class networks and
# the "loopback" interface. For more examples of the syntax see
# the smb.conf man page
;   hosts allow = 192.168.1. 192.168.2. 127.

# Uncomment this if you want a guest account, you must add this to /etc/passwd
# otherwise the user "nobody" is used
;  guest account = pcguest

# this tells Samba to use a separate log file for each machine
# that connects
   log file = /var/log/samba/log.%m

# Put a capping on the size of the log files (in Kb).
   max log size = 50

# Specifies the Kerberos or Active Directory realm the host is part of
;   realm = MY_REALM

# Backend to store user information in. New installations should
# use either tdbsam or ldapsam. smbpasswd is available for backwards
# compatibility. tdbsam requires no further configuration.
;   passdb backend = tdbsam

# Using the following line enables you to customise your configuration
# on a per machine basis. The %m gets replaced with the netbios name
# of the machine that is connecting.
# Note: Consider carefully the location in the configuration file of
#       this line.  The included file is read at that point.
;   include = /usr/local/samba/lib/smb.conf.%m

# Configure Samba to use multiple interfaces
# If you have multiple network interfaces then you must list them
# here. See the man page for details.
;   interfaces = 192.168.12.2/24 192.168.13.2/24

# Where to store roving profiles (only for Win95 and WinNT)
#        %L substitutes for this servers netbios name, %U is username
#        You must uncomment the [Profiles] share below
;   logon path = \\%L\Profiles\%U

# Windows Internet Name Serving Support Section:
# WINS Support - Tells the NMBD component of Samba to enable it's WINS Server
;   wins support = yes

# WINS Server - Tells the NMBD components of Samba to be a WINS Client
#       Note: Samba can be either a WINS Server, or a WINS Client, but NOT both
;   wins server = w.x.y.z

# WINS Proxy - Tells Samba to answer name resolution queries on
# behalf of a non WINS capable client, for this to work there must be
# at least one  WINS Server on the network. The default is NO.
;   wins proxy = yes

# DNS Proxy - tells Samba whether or not to try to resolve NetBIOS names
# via DNS nslookups. The default is NO.
   dns proxy = no

# These scripts are used on a domain controller or stand-alone
# machine to add or delete corresponding unix accounts
;  add user script = /usr/sbin/useradd %u
;  add group script = /usr/sbin/groupadd %g
;  add machine script = /usr/sbin/adduser -n -g machines -c Machine -d /dev/null -s /bin/false %u
;  delete user script = /usr/sbin/userdel %u
;  delete user from group script = /usr/sbin/deluser %u %g
;  delete group script = /usr/sbin/groupdel %g


#============================ Share Definitions ==============================
[homes]
   comment = Home Directories
   browseable = no
   writable = yes

# NOTE: If you have a BSD-style print system there is no need to
# specifically define each individual printer
[printers]
   comment = All Printers
   path = /usr/spool/samba
   browseable = no
   guest ok = no
   writable = no
   printable = yes
END_CAT

usermod -aG power,audio,video,storage,wheel,flatpak,libvirt,libvirt-qemu,games,kvm,rfkill,docker wiresandenergy

systemctl enable reflector

pacman -S git base-devel --needed

cd /home/wiresandenergy/
echo "Changed Directory"

su wiresandenergy -c 'git clone https://aur.archlinux.org/yay-bin.git'
cd yay-bin
su wiresandenergy -c 'makepkg -si'

su wiresandenergy -c 'yay -S apache-tools wsdd update-grub --needed'

sudo systemctl enable wsdd 

su wiresandenergy -c 'sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

su wiresandenergy -c "git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"

su wiresandenergy -c "sed -i 's|robbyrussell|cloud|g' ~/.zshrc"

su wiresandenergy -c "sed -i 's|plugins=(git)|plugins=(git\n\t zsh-autosuggestions)|g' ~/.zshrc"

su wiresandenergy -c "yay -S libreoffice-fresh notepadqq keepassxc steam discord handbrake telegram-desktop okular qbittorrent kodi flatpak remmina gparted zoom code shotcut nomachine kamoso konsole kitty nerds-fonts grub-customizer swtpm stow mkinitcpio-firmware thunderbird --needed"

mkdir -p /etc/sddm.conf.d/
cp /usr/lib/sddm/sddm.conf.d/default.conf /etc/sddm.conf.d/arch.conf

su wiresandenergy -c "mkdir -p /home/wiresandenergy/.config"

cat <<'END_CAT' > /home/wiresandenergy/.config/kwalletrc
[Wallet]
Enabled=false
END_CAT

chown wiresandenergy:wiresandenergy /home/wiresandenergy/.config/kwalletrc

su wiresandenergy -c 'yay -S timeshift timeshift-autosnap --noconfirm --needed'

printf "\e[1;32mDone! Type exit, umount -a and reboot.\e[0m"
