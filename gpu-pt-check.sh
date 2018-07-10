#!/bin/bash
DIR=$(cd "$(dirname "$0")"; pwd)

# Enable these to mock the lshw output and iommu groups of other computers for testing purposes
#LSHW_MOCK="$DIR/mock-data/3-lshw"
#LSIOMMU_MOCK="$DIR/mock-data/3-lsiommu"

if [ -z ${LSIOMMU_MOCK+x} ]; then
    IOMMU_GROUPS=$("$DIR/lsiommu.sh")
else
    IOMMU_GROUPS=$(cat "$LSIOMMU_MOCK")
fi

if [ -z ${LSHW_MOCK+x} ]; then
    GPU_INFO=$(sudo lshw -class display -businfo)
else
    GPU_INFO=$(cat "$LSHW_MOCK")
fi


NC='\033[0m' # No Color
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[1;33m'

function log_red() {
    echo -e "${RED}$@${NC}"
}
function log_green() {
    echo -e "${GREEN}$@${NC}"
}
function log_orange() {
    echo -e "${ORANGE}$@${NC}"
}

# Check if UEFI is configured correctly
if systool -m kvm_intel -v &> /dev/null || systool -m kvm_amd -v &> /dev/null ; then
    UEFI_VIRTUALIZATION_ENABLED=true
    log_green "[OK] VT-X / AMD-V virtualization is enabled in the UEFI."
else
    UEFI_VIRTUALIZATION_ENABLED=false
    log_orange "[Warning] VT-X / AMD-V virtualization is not enabled in the UEFI!"
fi

if [ "$IOMMU_GROUPS" != "" ] ; then 
    UEFI_IOMMU_ENABLED=true
    log_green "[OK] IOMMU / VT-D is enabled in the UEFI."
else
    UEFI_IOMMU_ENABLED=false
    log_red "[Error] IOMMU / VT-D is not enabled in the UEFI!"
fi

# Check if kernel is configured correctly
if cat /proc/cmdline | grep --quiet iommu ; then
    log_green "[OK] The IOMMU kernel parameters seem to be set."
else
    log_red "[Error] The iommu kernel parameters are missing!"
fi

GPU_IDS=($(echo "$GPU_INFO" | grep "pci@" | cut -d " " -f 1 | cut -d ":" -f 2-))

if [ "${#GPU_IDS[@]}" == "0" ] ; then
    log_red "[Warning] Failed to find any GPUs!"
elif [ "${#GPU_IDS[@]}" == "1" ] ; then
    log_orange "[Warning] Only 1 GPU found! (Counting all GPUs, not just dedicated ones.)"
fi

GOOD_GPUS=()
BAD_GPUS=()
for GPU_ID in "${GPU_IDS[@]}"; do
    GPU_IOMMU_GROUP=$(echo "$IOMMU_GROUPS" | grep $GPU_ID | cut -d " " -f 3)

    if [ "$GPU_IOMMU_GROUP" == "" ] ; then
        log_red "[Error] Failed to find the IOMMU group of the GPU with the ID $GPU_ID! Have you enabled iommu in the UEFI and kernel?"
    else
        OTHER_DEVICES_IN_GPU_GROUP=$(echo "$IOMMU_GROUPS" | grep "IOMMU Group $GPU_IOMMU_GROUP " | grep -v $GPU_ID | grep -v " Audio device " | grep -v " PCI bridge ")
        if [ "$OTHER_DEVICES_IN_GPU_GROUP" == "" ] ; then
            log_green "[Success] GPU with ID '$GPU_ID' could be passed through to a virtual machine!"
            GOOD_GPUS+=("$GPU_ID")
        else
            log_orange "[Problem] Other devices have been found in the IOMMU group of the GPU with the ID '$GPU_ID'. Depending on the devices, this could make GPU pass-through impossible to pass this GPU through to a virtual machine!"
            log_orange "The devices found in this GPU's IOMMU Group are:"
            log_red "$OTHER_DEVICES_IN_GPU_GROUP"
            echo "[Info] It might be possible to get it to work by putting the devices in different slots on the motherboard and or by using the ACS override patch. Otherwise you'll probably have to get a different motherboard. If you're on a laptop, there is nothing you can do as far as I'm aware. Although it would theoretically be possible for ACS support for laptops to exist. TODO: Find a way to check if the current machine has support for that."
            BAD_GPUS+=("$GPU_ID")
        fi
    fi
done

GPU_LIST="Is Compatible?|Name|IOMMU_GROUP|PCI Address"

for GPU_ID in "${BAD_GPUS[@]}"; do
    PCI_ADDRESS="pci@0000:${GPU_ID}"
    NAME=$(echo "$GPU_INFO" | grep "$GPU_ID" | tr -s " " | cut -d " " -f 3-)
    IOMMU_GROUP=$(echo "$IOMMU_GROUPS" | grep $GPU_ID | cut -d " " -f 3)
    GPU_LIST="${GPU_LIST}\nNo|${NAME}|${IOMMU_GROUP}|${PCI_ADDRESS}"
done

for GPU_ID in "${GOOD_GPUS[@]}"; do
    PCI_ADDRESS="pci@0000:${GPU_ID}"
    NAME=$(echo "$GPU_INFO" | grep "$GPU_ID" | tr -s " " | cut -d " " -f 3-)
    IOMMU_GROUP=$(echo "$IOMMU_GROUPS" | grep $GPU_ID | cut -d " " -f 3)
    GPU_LIST="${GPU_LIST}\nYes|${NAME}|${IOMMU_GROUP}|${PCI_ADDRESS}"
done

if [ "${#GOOD_GPUS[@]}" == "0" ] ; then
    log_red "[Warning] This script was not able to identify a GPU in this that could be passed through to a VM!"
else
    log_green "[Success] There seems to be at least one GPU in this system that can be passed through to a VM!"
fi

echo ""
GPU_LIST=$(echo -e "$GPU_LIST" | column -t -s'|')
while read -r line; do
    if echo "$line" | grep --quiet Yes ; then
        log_green "$line"
    elif echo "$line" | grep --quiet No ; then
        log_red "$line"
    else
        log_orange "$line"
    fi
done <<< "$GPU_LIST"
echo ""

#echo "Listing IOMMU Groups..."
#$DIR/lsiommu.sh

#echo "Listing GPU info with lshw..."
#sudo lshw -class display

$SHELL # This is just to keep the shell running when the script is automatically executed on startup.
