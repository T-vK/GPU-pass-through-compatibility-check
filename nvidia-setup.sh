#!/bin/bash

GRUB_CFG_PATH=/etc/default/grub

function addKernelParam() {
    if ! sudo cat "$GRUB_CFG_PATH" | grep "GRUB_CMDLINE_LINUX=" | grep --quiet "$1"; then
        sudo sed -i "s/^GRUB_CMDLINE_LINUX=\"/&$1 /" "$GRUB_CFG_PATH"
        echo "addKernelParam: Added \"$1\" to GRUB_CMDLINE_LINUX in $GRUB_CFG_PATH"
    else
        echo "addKernelParam: No action required. \"$1\" already exists in GRUB_CMDLINE_LINUX of $GRUB_CFG_PATH"
    fi
}
function removeKernelParam() {
    if sudo cat "$GRUB_CFG_PATH" | grep "GRUB_CMDLINE_LINUX=" | grep --quiet "$1"; then
        sudo sed -i "s/$1 //" "$GRUB_CFG_PATH"
        echo "removeKernelParam: Removed \"$1\" from GRUB_CMDLINE_LINUX in $GRUB_CFG_PATH"
    else
        echo "removeKernelParam: No action required. \"$1\" is not set in GRUB_CMDLINE_LINUX of $GRUB_CFG_PATH"
    fi
}
function applyKernelParamChanges() {
    sudo sh -c 'grub2-mkconfig > /etc/grub2-efi.cfg'
}


#sudo dnf install fedora-workstation-repositories -y

#sudo dnf config-manager rpmfusion-nonfree-nvidia-driver --set-enabled -y

#sudo dnf install akmod-nvidia acpi -y

#sudo dnf copr enable chenxiaolong/bumblebee -y

#sudo dnf install akmod-bbswitch bumblebee primus -y

#sudo gpasswd -a $USER bumblebee

#sudo systemctl enable bumblebeed
#sudo systemctl mask nvidia-fallback


removeKernelParam "acpi_osi=!"
addKernelParam "acpi_osi='Windows 2009'"
addKernelParam "nouveau.modeset=0"

applyKernelParamChanges
