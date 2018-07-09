#!/bin/bash

# Enable these to mock the lshw output and iommu groups of other computers for testing purposes
#LSHW_MOCK=./mock-data/1-lshw
#LSIOMMU_MOCK=./mock-data/1-lsiommu

if [ -z ${LSHW_MOCK+x} ]; then
    GPU_IDS=($(sudo lshw -class display | grep "bus info" | cut -d ":" -f 3-))
else
    GPU_IDS=($(cat "$LSHW_MOCK" | grep "bus info" | cut -d ":" -f 3-))
fi

if [ "${#GPU_IDS[@]}" == "0" ] ; then
    echo "Warning: Failed to find any GPUs!"
elif [ "${#GPU_IDS[@]}" == "1" ] ; then
    echo "Warning: Only 1 GPU found! (Counting all GPUs, not just dedicated ones.)"
fi

GPU_FOR_PASS_THROUGH_FOUND=false
declare -a GPU_IOMMU_GROUPS
for GPU_ID in "${GPU_IDS[@]}"; do
    if [ -z ${LSIOMMU_MOCK+x} ]; then
        GPU_IOMMU_GROUP=$(./lsiommu.sh | grep $GPU_ID | cut -d " " -f 3)
    else
        GPU_IOMMU_GROUP=$(cat "$LSIOMMU_MOCK" | grep $GPU_ID | cut -d " " -f 3)
    fi

    if [ "$GPU_IOMMU_GROUP" == "" ] ; then
        echo "Error: Failed to find the IOMMU group of the GPU with the ID $GPU_ID! Have you enabled iommu in the UEFI and kernel?"
    else
        echo "GPU ID: $GPU_ID - GPU IOMMU group: $GPU_IOMMU_GROUP"
        if [ -z ${LSIOMMU_MOCK+x} ]; then
            OTHER_DEVICES_IN_GPU_GROUP=$(./lsiommu.sh | grep "IOMMU Group $GPU_IOMMU_GROUP" | grep -v $GPU_ID | grep -v " Audio device ")
        else
            OTHER_DEVICES_IN_GPU_GROUP=$(cat "$LSIOMMU_MOCK" | grep "IOMMU Group $GPU_IOMMU_GROUP" | grep -v $GPU_ID | grep -v " Audio device ")
        fi
        if [ "$OTHER_DEVICES_IN_GPU_GROUP" == "" ] ; then
            echo "Success: GPU with ID '$GPU_ID' could be passed through to a virtual machine!"
            GPU_FOR_PASS_THROUGH_FOUND=true
        else
            echo "Problem: Other devices have been found in the IOMMU group of the GPU with the ID '$GPU_ID'. Depending on the devices, this could make GPU pass-through impossible to pass this GPU through to a virtual machine!"
            echo "The devices found in this GPU's IOMMU Group are:"
            echo "$OTHER_DEVICES_IN_GPU_GROUP"
            echo "It might be possible to get it to work by putting the devices in different slots on the motherboard and or by using the ACS override patch. Otherwise you'll probably have to get a different motherboard. If you're on a laptop, there is nothing you can do as far as I'm aware. Although it would theoretically be possible for ACS support for laptops to exist. TODO: Find a way to check if the current machine has support for that."
        fi
    fi
done

echo "----------------------------------------------"
if [ "$GPU_FOR_PASS_THROUGH_FOUND" == true ] ; then
    echo "Success: There seems to be at least one GPU in this system that can be passed through to a VM!"
else
    echo "This script was not able to identify a GPU in this that could be passed through to a VM!"
fi

#echo "Listing IOMMU Groups..."
#./lsiommu.sh

#echo "Listing GPU info with lshw..."
#sudo lshw -class display

$SHELL # This is just to keep the shell running when the script is automatically executed on startup.
