# GPU-pass-through-compatibility-check

## Introduction
This project contains instructions on how to create a bootable Linux USB stick that automatically checks to what extend a computer is compatible with GPU pass-through. This project has primarely be created to check notebooks. It will probably also work on desktop computers, but checking how and if the conenction between the GPU and the display is MUXED wouldn't make much sense on a desktop computer.

## TODO
- [x] Instructions on creating a bootable Linux stick with persistent storage, UEFI compability and a recent kernel (4.17+)
- [x] check if Linux still boots if you add iommu kernel params for Intel and AMD at the same time
- [x] if it works: write a script to automatically add the kernel parameters to the system
- [x] install basic tools like git in the script which might come in handy
- [x] install virtualization software using the script
- [x] find a way to skip the login screen and automatically run a bash script with root privileges that:
- [x] automatically checks if the iommu groups setup would work for GPU pass-trough
- [ ] automatically finds out the GPU is connected to the screen and the external outputs (MUX-less, MUXED etc.)
- [ ] automatically verifies that it works by actually booting a VM and passing the GPU through to it.
- [ ] Add login to detect if the kernel parameters are set
- [ ] Add logic to check if the virtualization technologies have been ebaled in the UEFI (possiby using rdmsr?)

## Prerequisites

- a USB stick with at least 16GB of storage (let's call this one the Fedora stick)
- an x64 installation image for Fedora 28 or above: https://getfedora.org/en/workstation/download/
- another USB stick with at least 2GB of storage (let's call this one the install stick) OR some experience with virtual machines

## Setup

### Installing Fedora 28 x64 on a USB stick
You have two options:

#### Installing Fedora using another USB stick
This this case you a install stick. You need to follow the instructions on the Fedora website to turn it into a bootable Fedora installation USB stick: https://getfedora.org/en/workstation/download/
Then you need to boot from it in EFI / UEFI / non-BIOS mode. Usually when you open up the boot menu when you PC starts, you get multiple entries for your USB stick. You want to pick the one that says UEFI or EFI / or non-BIOS ...
Then you wait for it to boot up and follow the instructions to install Fedora on the Fedora stick.

#### Installing Fedora using a virtual machine
Alternatively you can create a VM with a UEFI firmare (in virtual machine manager: [1](screenshots/vm-advanced-config.png), [2](screenshots/vm-uefi.png)) and pass the Fedora stick through to it (in virtual machine manager: [3](screenshots/vm-usb-pass-through.png)) and tell the VM to boot from the Fedora iso image directly. You don't need a storage device (vhd)! Then you simply boot the VM (make sure it boots from the iso image and follow the instructions to install Fedora on the Fedora stick.

### Adding the setup script.

Now to add the setup script to the USB stick, simply boot from the USB stick (either using the VM (you should remove the virtual CD drive frist, so that it won't boot from the iso again) or boot from it directly (in EFI / UEFI ... mode!)). Then run the following commands to download the setup script and execute it with root privileges:

```
curl -O https://raw.githubusercontent.com/T-vK/GPU-pass-through-compatibility-check/master/setup.sh
chmod +x ./setup.sh
sudo ./setup.sh
```

## Usage
- On the computer you want to check you first have to go to the UEFI and enable virtualization. On AMD CPU systems: AMD-V and IOMMU. And on Intel CPU systems: VT-x and VT-d. (Beware: Some motherboard vendors get pretty creative when it comes to giving these options other names.)
- You should enable the internal GPU of the CPU so that you have two (one for the host one for the guest system)
  (some vendors actually disable the CPU internal GPU completely and don't offer UEFI options to enable it)
- You might also have to disable secure boot in the UEFI.
- It might also be necessary to disable fastboot in the UEFI.
- Once you saved the settings and rebooted, enter the boot menu (usually with Esc, F1-F12 or Del) and boot your Fedora stick in EFI / UEFI / non-BIOS mode.
- Finally when it boots the rest should happen automatically. (Work in progress. This will not work atm.)
