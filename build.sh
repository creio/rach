#!/usr/bin/bash

image_name="archlinux-$(date +%Y.%m.%d)-x86_64.iso"

echo "install pkg"
pacman -Syy git archiso mkinitcpio-archiso --noconfirm --needed

build_iso() {
  pacman -Scc --noconfirm --quiet
  rm -rf /var/cache/pacman/pkg/*
  pacman-key --init
  pacman-key --populate
  pacman -Syy --quiet

  echo "copy chroot.sh"
  cp -r chroot.sh /usr/share/archiso/configs/releng/
  echo $PWD
  [[ $(grep chroot.sh /usr/bin/mkarchiso) ]] || \
  sed -i "/_mkairootfs_squashfs()/a [[ -e "$\{profile\}/chroot.sh" ]] && $\{profile\}/chroot.sh" /usr/bin/mkarchiso
  cat /usr/bin/mkarchiso | grep chroot.sh
  echo "START mkarchiso"
  mkarchiso -v -w /usr/share/archiso/configs/releng/work -o /out /usr/share/archiso/configs/releng/
}

echo "build iso"
build_iso

if [[ -e "/out/$img_name" ]]; then
  echo "create SHA 256"
  sha256sum /out/$image_name >> /out/$image_name.sha256

  echo "add gh env"
  echo "BUILD_TAG=$(date +%Y.%m.%d)" >> $GITHUB_ENV
  echo "image_name=$image_name" >> $GITHUB_ENV
fi
