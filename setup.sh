#!/bin/bash
sudo dnf update -y
sudo dnf install -y vim screen git wget curl
sudo dnf install -y @virtualization

export GRUB_CFG_PATH=/etc/default/grub
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

addKernelParam "iommu=1"
addKernelParam "amd_iommu=on"
addKernelParam "rd.driver.pre=vfio-pci"
addKernelParam "intel_iommu=on"

sudo dracut -f --kver `uname -r`

sudo sh -c 'grub2-mkconfig > /etc/grub2-efi.cfg'

# disable the lock screen
# automatically run the following script with root privileges on every boot without having to do anyhting

# curl -O https://github.com/T-vK/GPU-pass-through-compatibility-check/startup.sh
# chmod +x startup.sh
