#!/usr/bin/bash

image_name="archlinux-$(date +%Y.%m.%d)-x86_64.iso"

echo "install pkg"
pacman -Syy git archiso mkinitcpio-archiso --noconfirm --needed

echo "build iso"
mkarchiso -v -w ./work -o ./out /usr/share/archiso/configs/releng/

if [[ -e "./out/$img_name" ]]; then
  echo "create SHA 256"
  sha256sum ./out/$image_name >> ./out/$image_name.sha256
  echo "image_name=$image_name" >> $GITHUB_ENV
fi
