#!/bin/bash

#echo "Listing IOMMU Groups..."
#./lsiommu.sh

#echo "Listing GPU info with lshw..."
#sudo lshw -class display


export GPU_ID=$(sudo lshw -class display | grep "bus info" | cut -d ":" -f 3-)
#export GPU_ID=$(cat lshw-mock | grep "bus info" | cut -d ":" -f 3-)
export GPU_IOMMU_GROUP=$(./lsiommu.sh | grep $GPU_ID | cut -d " " -f 3)
#export GPU_IOMMU_GROUP=$(cat iommu-mock | grep $GPU_ID | cut -d " " -f 3)
export OTHER_DEVICES_IN_GPU_GROUP=$(./lsiommu.sh | grep "IOMMU Group 13" | grep -v $GPU_ID | grep -v " Audio device ")
#export OTHER_DEVICES_IN_GPU_GROUP=$(cat iommu-mock | grep "IOMMU Group 13" | grep -v $GPU_ID | grep -v " Audio device ")
# (All GPUs I've seen so far are tied to some sort of audio device, probably because of HDMI audio; thus these devices are filtered out.)

if [ "$GPU_ID" == "" ] ; then
    echo "Warning: Failed to find a dedicated GPU!"
fi

if [ "$GPU_IOMMU_GROUP" == "" ] ; then
    echo "Warning: Failed to find the GPU's IOMMU group!"
fi

echo "GPU ID: $GPU_ID"
echo "GPU IOMMU Group: $GPU_IOMMU_GROUP"

if [ "$OTHER_DEVICES_IN_GPU_GROUP" == "" ] && [ "$GPU_ID" != "" ] && [ "$GPU_IOMMU_GROUP" != "" ] ; then
    echo "Success: IOMMU groups should be compatible with GPU pass-through!"
else
    echo "Problem: Other devices have been found in the GPUs IOMMU group. Depending on the tied devices, this could make GPU pass-through impossible on this machine!"
    echo "Other devices in the GPU IOMMU Group: $OTHER_DEVICES_IN_GPU_GROUP"
fi


$SHELL
