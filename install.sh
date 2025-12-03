#!/usr/bin/env bash

# Set up distroboxes before running this!
# ubuntu image: quay.io/toolbx/ubuntu-toolbox
distrobox enter ubuntu -- bash -c "
    sudo apt update && sudo apt upgrade -y \
    sudo apt install -y devscripts dput curl build-essential whiptail libdw-dev gcc libncurses-dev curl gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf make rustc bc rsync python-is-python3 perl gettext cpio pahole debhelper dwarves zstd \
    exit 0"
# fedora image: quay.io/fedora/fedora-toolbox
distrobox enter fedora -- bash -c "
    sudo dnf upgrade -y \
    sudo dnf install rpm-build desktop-file-utils -y \
    exit 0"

# photogimp setup
wget https://github.com/Diolinux/PhotoGIMP/releases/download/3.0/PhotoGIMP-linux.zip
unzip PhotoGIMP-linux.zip
cd PhotoGIMP/.config
rsync -a --remove-source-files GIMP/ ~/.config/GIMP/
cd ../../
rm -r PhotoGIMP

echo "All tasks complete!"
sleep 2
exit 0
