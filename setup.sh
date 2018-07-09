#!/bin/bash

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

function gnomeEnableAutoLogin() {
    sudo crudini --set /etc/gdm/custom.conf daemon AutomaticLoginEnable True
    sudo crudini --set /etc/gdm/custom.conf daemon AutomaticLogin $USER
}

function gnomeDisableAutoLogin() {
    sudo crudini --set /etc/gdm/custom.conf daemon AutomaticLoginDisable False
    sudo crudini --set /etc/gdm/custom.conf daemon AutomaticLogin $USER
}

function enablePasswordlessSudo() {
    if ! sudo cat "/etc/sudoers" | grep --quiet "^$USER ALL=(ALL) NOPASSWD:ALL"; then
        echo "$USER ALL=(ALL) NOPASSWD:ALL" >> "/etc/sudoers"
        echo "enablePasswordlessSudo: Password-less sudo has been enabled for the current user: $USER"
    else
        echo "enablePasswordlessSudo: No action required. Password-less sudo is already configured for the current user: $USER"
    fi
}
function disablePasswordlessSudo() {
    if sudo cat "/etc/sudoers" | grep --quiet "^$USER ALL=(ALL) NOPASSWD:ALL"; then
        sudo sed -i "s/^$USER ALL=(ALL) NOPASSWD:ALL//g" "/etc/sudoers"
        echo "disablePasswordlessSudo: Password-less sudo has been disabled for the current user: $USER"
    else
        echo "disablePasswordlessSudo: No action required. Password-less sudo is not enabled for the current user: $USER"
    fi
}

# Allow sudo to be used without a password for the current user
enablePasswordlessSudo

# Install to tools that will come in handy
sudo dnf update -y
sudo dnf install -y vim screen git crudini
sudo dnf install -y @virtualization

# Add kernel parameters to enable iommu on Intel/AMD CPUs
addKernelParam "iommu=1"
addKernelParam "amd_iommu=on"
addKernelParam "rd.driver.pre=vfio-pci"
addKernelParam "intel_iommu=on"

# Do something with the initial RAM disk because something vfio...
sudo dracut -f --kver `uname -r`

# Apply the kernel parameter changes
sudo sh -c 'grub2-mkconfig > /etc/grub2-efi.cfg'

# Disable the login screen directly after booting
gnomeEnableAutologin

# Download autostart script
curl -O https://github.com/T-vK/GPU-pass-through-compatibility-check/autostart.sh
chmod +x autostart.sh

# Configure autostart script to start when logged in after boot
mkdir -p $HOME/.config/autostart
echo "[Desktop Entry]" > $HOME/.config/autostart/gpu-pass-through-check.desktop
echo "Name=GPU pass-through check" >> $HOME/.config/autostart/gpu-pass-through-check.desktop
echo "Exec=$HOME/autostart.sh" >> $HOME/.config/autostart/gpu-pass-through-check.desktop
echo "Terminal=true" >> $HOME/.config/autostart/gpu-pass-through-check.desktop
echo "Type=Application" >> $HOME/.config/autostart/gpu-pass-through-check.desktop
chmod +x $HOME/.config/autostart/gpu-pass-through-check.desktop
gio set $HOME/.config/autostart/gpu-pass-through-check.desktop "metadata::trusted" yes

