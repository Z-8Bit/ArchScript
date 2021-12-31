#!/bin/bash

echo "Please enter your preferred username."
read username

echo "Please enter your preferred hostname."
read hostname

echo "Please enter your user and root password."
read password

lsblk
echo "Please enter your preferred boot directory like (/dev/sda2)."
read boot

echo "Please enter your preferred root directory like (/dev/sda6)."
read root

echo "Please enter your preferred timezone like (Asia/Kolkata)"
read timezone

timedatectl set-ntp true
timedatectl status

mkfs.fat -F32 -n "BOOT" ${boot}
mkfs.ext4 -L "ROOT" ${root}
# mkswap /dev/sda7
# swapon /dev/sda7
mount ${root} /mnt
mkdir /boot/efi
mount ${boot} /boot/efi

sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 10/g" /etc/pacman.conf  # Parallel downloads

pacstrap /mnt base linux linux-firmware sudo
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt /bin/bash -e <<EOF

# Timezone
ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime
hwclock --systohc

# Locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# Hostname 
echo ${hostname} >> /etc/hostname
echo -e "127.0.0.1\tlocalhost" >> /etc/hosts
echo -e "::1\t\tlocalhost" >> /etc/hosts
echo -e "127.0.1.1\t${hostname}.localdomain\t${hostname}" >> /etc/hosts
echo root:${password} | chpasswd

# Pacman Configuration
sed -i "/#Color/a ILoveCandy" /etc/pacman.conf  # Making pacman prettier
sed -i "s/#Color/Color/g" /etc/pacman.conf  # Add color to pacman
sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 10/g" /etc/pacman.conf  # Parallel downloads

#Package Downloading
pacman -S efibootmgr vim networkmanager network-manager-applet wpa_supplicant mtools dosfstools reflector base-devel linux-headers avahi gvfs os-prober ntfs-3g bluez bluez-utils git neofetch --noconfirm

# grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB 
# grub-install --target=x86_64-efi  --bootloader-id=Arch --recheck
# grub-mkconfig -o /boot/grub/grub.cfg
# echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub 
# grub-mkconfig -o /boot/grub/grub.cfg

for service in bluetooth NetworkManager; do
  systemctl enable --now $service
done

# Username
useradd -m ${username}
echo "${username}":"${password}" | chpasswd
usermod -aG wheel,audio,video,optical,storage "${username}"

echo "${username} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/${username}

EOF

printf "\e[1;32mDone! Type exit, umount -a and reboot.\e[0m"