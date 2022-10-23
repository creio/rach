#!/usr/bin/env bash
set -e -u

script_path=$(readlink -f ${0%/*})
work_dir=/usr/share/archiso/configs/releng/work/x86_64/airootfs

echo "==== create settings.sh ===="
sed '1,/^#chroot$/d' /usr/share/archiso/configs/releng/chroot.sh >${work_dir}/settings.sh

chrooter() {
  arch-chroot ${work_dir} /bin/bash -c "${1}"
}

chmod +x ${work_dir}/settings.sh
chrooter /settings.sh
rm ${work_dir}/settings.sh
exit 0

#chroot
isouser="liveuser"
OSNAME="rach"

_conf() {
  ln -sf /usr/share/zoneinfo/UTC /etc/localtime
  hwclock --systohc --utc
  sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
  sed -i "s/#\(ru_RU\.UTF-8\)/\1/" /etc/locale.gen
  locale-gen
  echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
  echo "LC_COLLATE=C" >> /etc/locale.conf
  echo "KEYMAP=ru" > /etc/vconsole.conf
  echo "FONT=cyr-sun16" >> /etc/vconsole.conf
  echo "$OSNAME" > /etc/hostname
  export _BROWSER=firefox
  echo "BROWSER=/usr/bin/${_BROWSER}" >> /etc/environment
  export _EDITOR=nano
  echo "EDITOR=${_EDITOR}" >> /etc/environment
  echo "QT_QPA_PLATFORMTHEME=qt5ct" >> /etc/environment
  sed -i '/User/s/^#\+//' /etc/sddm.conf
  sed -i '/CheckSpace/s/^#\+//' /etc/pacman.conf
}

_perm() {
  mkdir -p /media
  chmod 755 -R /media
  chmod +x /usr/local/bin/*
  # chmod +x /etc/skel/.bin/*
  # chmod +x /home/$isouser/.bin/*
  # find /etc/skel/ -type f -iname "*.sh" -exec chmod +x {} \;
  # find /home/$isouser/ -type f -iname "*.sh" -exec chmod +x {} \;
}

_liveuser() {
  glist="audio,disk,log,network,scanner,storage,power,wheel"
  if ! id $isouser 2>/dev/null; then
    useradd -m -p "" -c "Liveuser" -g users -G $glist -s /usr/bin/zsh $isouser
    echo "$isouser ALL=(ALL) ALL" >> /etc/sudoers
  fi
}

_nm() {
  echo "" > /etc/NetworkManager/NetworkManager.conf
  echo "[device]" >> /etc/NetworkManager/NetworkManager.conf
  echo "wifi.scan-rand-mac-address=no" >> /etc/NetworkManager/NetworkManager.conf
  echo "" >> /etc/NetworkManager/NetworkManager.conf
  echo "[main]" >> /etc/NetworkManager/NetworkManager.conf
  echo "dhcp=dhclient" >> /etc/NetworkManager/NetworkManager.conf
  echo "dns=systemd-resolved" >> /etc/NetworkManager/NetworkManager.conf
}

_key() {
  reflector -a 12 -l 15 -p https,http --sort rate --save /etc/pacman.d/mirrorlist
  pacman-key --init
  pacman-key --populate
  pacman -Syy --noconfirm
}

_drsed() {
  sed -i /etc/lsb-release \
    -e 's|distrib_id=.*|distrib_id=rach|' \
    -e 's|distrib_release=.*|distrib_release=rolling|' \
    -e 's|distrib_codename=.*|distrib_codename=anon|' \
    -e 's|distrib_description=.*|distrib_description=\"rach linups\"|'

  sed -i /usr/lib/os-release \
    -e 's|name=.*|name=\"rach linups\"|' \
    -e 's|pretty_name=.*|pretty_name=\"rach linups\"|' \
    -e 's|id=.*|id=rach|' \
    -e 's|id_like=.*|id_like=rach|' \
    -e 's|build_id=.*|build_id=rolling|' \
    -e 's|home_url=.*|home_url=\"https://rach.github.io\"|' \
    -e 's|documentation_url=.*|documentation_url=\"https://rach.github.io/wiki\"|' \
    -e 's|support_url=.*|support_url=\"https://forum.rach.ru\"|' \
    -e 's|bug_report_url=.*|bug_report_url=\"https://github.com/creio/rach/issues\"|' \
    -e 's|logo=.*|logo=rach|'

  sed -i 's|Arch|Rach|g' /etc/issue /usr/share/factory/etc/issue
}

_serv() {
  systemctl mask systemd-rfkill@.service
  systemctl mask systemd-rfkill.socket
  systemctl enable haveged.service
  systemctl enable pacman-init.service
  systemctl enable choose-mirror.service
  systemctl enable vbox-check.service
  # systemctl enable avahi-daemon.service
  # systemctl enable systemd-networkd.service
  # systemctl enable systemd-resolved.service
  # systemctl enable systemd-timesyncd.service
  systemctl enable ModemManager.service
  systemctl -f enable NetworkManager.service
  # systemctl enable iwd.service
  systemctl enable reflector.service
  systemctl enable sshd.service
  systemctl enable sddm.service
  systemctl set-default graphical.target
}

_pkgs() {
    pacman -Syy base-devel git --noconfirm --needed
    cd /home/$isouser; git clone https://aur.archlinux.org/yay-bin.git
    chown -R $isouser:users /home/$isouser/yay-bin
    cd /home/$isouser/yay-bin; sudo -u $isouser makepkg -c -C -f -s --noconfirm --needed; pacman -U --noconfirm *.pkg.tar.zst
}

_conf
_perm
_liveuser
# _nm
_key
_drsed
# _serv
_pkgs

# sed -i 's|GRUB_DISTRIBUTOR=.*|GRUB_DISTRIBUTOR=\"Rach\"|' /etc/default/grub
# sed -i 's|\#GRUB_THEME=.*|GRUB_THEME=\/boot\/grub\/themes\/crimson\/theme.txt|g' /etc/default/grub
# echo 'GRUB_DISABLE_SUBMENU=y' >> /etc/default/grub
# wget https://github.com/rach/rach-sh/raw/master/cleaner.sh
# chmod +x cleaner.sh
# mv cleaner.sh /usr/local/bin/

echo "==== Done settings.sh ===="
