#!/usr/bin/env bash

# Set up distroboxes before running this!
# ubuntu image: ghcr.io/ublue-os/ubuntu-toolbox
distrobox enter ubuntu -- bash -c "
    sudo apt update && sudo apt upgrade -y \
    echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections \
    wget https://vscode.download.prss.microsoft.com/dbazure/download/stable/7d842fb85a0275a4a8e4d7e040d2625abbf7f084/code_1.105.1-1760482543_amd64.deb \
    sudo apt install ./code_1.105.1-1760482543_amd64.deb \
    sudo apt install -y git curl build-essential whiptail libdw-dev gcc git libncurses-dev curl gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf make rustc bc rsync python-is-python3 perl gettext cpio pahole debhelper dwarves zstd \
    curl -sS https://starship.rs/install.sh | sh \
    exit 0"
# fedora image: ghcr.io/ublue-os/fedora-toolbox
distrobox enter fedora -- bash -c "
    sudo dnf upgrade -y \
    sudo dnf install rpm-build \
    curl -sS https://starship.rs/install.sh | sh \
    exit 0"
# arch image: ghcr.io/ublue-os/arch-toolbox
distrobox enter arch -- bash -c "
    sudo pacman -Syu --noconfirm \
    sudo pacman -S --noconfirm prismlauncher base-devel intel-media-sdk vpl-gpu-rt qt6-wayland \
    paru -S --skipreview --noconfirm vintagestory heroic-games-launcher-bin gpu-screen-recorder-ui obs-studio-browser \
    curl -sS https://starship.rs/install.sh | sh \
    exit 0"
# set up GSR autostart
mkdir -p ~/.config/autostart
wget -O ~/.config/autostart/gsr-ui.desktop https://raw.githubusercontent.com/psygreg/nix-configuration/main/resources/gsr-ui.desktop
# enable starship on NixOS and all distroboxes
wget -O ~/.bash_profile https://raw.githubusercontent.com/psygreg/nix-configuration/main/resources/bash_profile
wget -O ~/.bashrc https://raw.githubusercontent.com/psygreg/nix-configuration/main/resources/bashrc

echo "All tasks complete!"
sleep 2
exit 0