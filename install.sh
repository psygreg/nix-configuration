#!/usr/bin/env bash

# Set up distroboxes before running this!
# ubuntu image: quay.io/toolbx/ubuntu-toolbox
distrobox enter ubuntu -- bash -c "
    sudo apt update && sudo apt upgrade -y \
    echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections \
    wget https://vscode.download.prss.microsoft.com/dbazure/download/stable/7d842fb85a0275a4a8e4d7e040d2625abbf7f084/code_1.105.1-1760482543_amd64.deb \
    sudo apt install ./code_1.105.1-1760482543_amd64.deb \
    sudo apt install -y gnome-keyring git curl build-essential whiptail libdw-dev gcc git libncurses-dev curl gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf make rustc bc rsync python-is-python3 perl gettext cpio pahole debhelper dwarves zstd \
    curl -sS https://starship.rs/install.sh | sh \
    exit 0"
# fedora image: quay.io/fedora/fedora-toolbox
distrobox enter fedora -- bash -c "
    sudo dnf upgrade -y \
    sudo dnf install rpm-build \
    curl -sS https://starship.rs/install.sh | sh \
    exit 0"
# enable starship on NixOS and all distroboxes
wget -O ~/.bash_profile https://raw.githubusercontent.com/psygreg/nix-configuration/main/resources/bash_profile
wget -O ~/.bashrc https://raw.githubusercontent.com/psygreg/nix-configuration/main/resources/bashrc

# change to unstable channel
sudo nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixos
sudo nix-channel --update

# sources.nix by niv fix
sudo cp ~/.nix/* /etc/nixos
ln -s /etc/nixos/sources.nix ~/.nix/sources.nix
ln -s /etc/nixos/sources.json ~/.nix/sources.json

echo "All tasks complete!"
sleep 2
exit 0
