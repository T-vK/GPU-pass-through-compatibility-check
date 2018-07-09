#!/bin/bash

echo "Listing IOMMU Groups..."
./lsiommu.sh

echo "Listing GPU info with lshw..."
sudo lshw -class display

$SHELL
