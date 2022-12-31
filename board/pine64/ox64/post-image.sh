#!/bin/bash

BOARD_DIR="$(dirname $0)"

echo "Compressing kernel image with lz4..."
${HOST_DIR}/bin/lz4 -9 -f ${BINARIES_DIR}/Image ${BINARIES_DIR}/Image.lz4

echo "Renaming device tree binary..."
cp ${BINARIES_DIR}/hw808c.dtb ${BINARIES_DIR}/hw.dtb.5M

echo "Renaming SquashFS image..."
cp ${BINARIES_DIR}/rootfs.squashfs ${BINARIES_DIR}/squashfs_test.img

echo "Creating output image..."
cp ${BOARD_DIR}/bl808_linux/out/merge_7_5Mbin.py ${BINARIES_DIR}/
cd ${BINARIES_DIR}
${HOST_DIR}/bin/python3 merge_7_5Mbin.py

cd ~-

