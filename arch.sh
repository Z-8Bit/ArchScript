#!/bin/bash

timedatectl set-ntp true
timedatectl status

mkfs.fat -F32 -n "BOOTWHA" /dev/sda6
mkfs.ext4 -L "ROOTWHA" /dev/sda9
# mkswap /dev/sda7
# swapon /dev/sda7
mount /dev/sda9 /mnt
mkdir /boot/efi
mount /dev/sda6 /boot/efi

sed -i 's/#ParallelDownloads/ParallelDownloads/g' /etc/pacman.conf

pacstrap /mnt base linux linux-firmware sudo
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt /bin/bash -e <<EOF

ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "zish" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 zish.localdomain zish" >> /etc/hosts
echo "root:1805" | chpasswd
sed -i 's/#ParallelDownloads/ParallelDownloads/g' /etc/pacman.conf

pacman -S efibootmgr vim networkmanager network-manager-applet wpa_supplicant mtools dosfstools reflector base-devel linux-headers avahi gvfs os-prober ntfs-3g bluez bluez-utils git neofetch powertop --noconfirm

# grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB 
# grub-mkconfig -o /boot/grub/grub.cfg
# echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub 
# grub-mkconfig -o /boot/grub/grub.cfg
# pacman -S refind && refind install 

echo -e "[Unit]
Description=Powertop tunings

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/powertop --auto-tune

[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/powertop.service

for service in bluetooth NetworkManager; do
  systemctl enable $service
done

useradd -m zishaan
echo "zishaan:1805" | chpasswd
usermod -aG wheel,audio,video,optical,storage,input zishaan

echo "zishaan ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/zishaan

EOF

printf "\e[1;32mDone! Type exit, umount -a and reboot.\e[0m"
