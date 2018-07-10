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

function setGrubTimeout() {
    sudo sed -i -r "s/^GRUB_TIMEOUT=[0-9]+/GRUB_TIMEOUT=$1 /" "$GRUB_CFG_PATH"
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

echo "Allow sudo to be used without a password for the current user..."
enablePasswordlessSudo

echo "Disable lock screen and screen blackout"
gsettings set org.gnome.desktop.screensaver lock-enabled false
gsettings set org.gnome.desktop.session idle-delay 0

echo "Updating software..."
sudo dnf update -y
echo "Install some useful tools..."
sudo dnf install -y vim screen git crudini lshw msr-tools sysfsutils
echo "Install virtualization software..."
sudo dnf install -y @virtualization

echo "Add kernel parameters to enable iommu on Intel/AMD CPUs"
# Docs: https://www.kernel.org/doc/Documentation/admin-guide/kernel-parameters.txt
# More docs: https://lwn.net/Articles/252826/
# https://www.kernel.org/doc/Documentation/x86/x86_64/boot-options.txt
addKernelParam "iommu=1" # '1' is not a documented option. stop confusing me wendell! Maybe the "force" option should be used instead?
addKernelParam "amd_iommu=on" # 'on' is not a docuemnted option for this parameter either! This is insanely confusing!
addKernelParam "intel_iommu=on" # enable Intel VT-D
addKernelParam "rd.driver.pre=vfio-pci" # tell dracut to load vfio-pci first
# addKernelParam "i915.preliminary_hw_support=1" # add skylake support; probably only necessary with older kernels

echo "Reduce grub timeout to 1 sec to reduce boot time"
setGrubTimeout 1

echo "Do something with the initial RAM disk because something vfio..."
sudo dracut -f --kver `uname -r`

echo "Apply the kernel parameter changes"
sudo sh -c 'grub2-mkconfig > /etc/grub2-efi.cfg'

echo "Disable the login screen directly after booting"
gnomeEnableAutoLogin

echo "Download autostart script..."
curl -O https://raw.githubusercontent.com/T-vK/GPU-pass-through-compatibility-check/master/autostart.sh
chmod +x autostart.sh

echo "Configure autostart script to start when logged in after boot"
AUTOSTART_SCRIPT=$(cd "$(dirname "$0")"; pwd)/gpu-pt-check.sh
mkdir -p $HOME/.config/autostart
echo "[Desktop Entry]" > $HOME/.config/autostart/gpu-pass-through-check.desktop
echo "Name=GPU pass-through check" >> $HOME/.config/autostart/gpu-pass-through-check.desktop
echo "Exec=$AUTOSTART_SCRIPT" >> $HOME/.config/autostart/gpu-pass-through-check.desktop
echo "Terminal=true" >> $HOME/.config/autostart/gpu-pass-through-check.desktop
echo "Type=Application" >> $HOME/.config/autostart/gpu-pass-through-check.desktop
chmod +x $HOME/.config/autostart/gpu-pass-through-check.desktop
gio set $HOME/.config/autostart/gpu-pass-through-check.desktop "metadata::trusted" yes

echo "You should reboot now!"
