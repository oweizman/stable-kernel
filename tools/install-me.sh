#!/bin/bash

#Note: too change, mmc mount directory run:
#export MMC=/dev/sdX1
#/bin/bash install-me.sh

ARCH=$(uname -m)
VER=$(echo $1 | awk -F"-|_" '{print $3"-"$4}')
if [ "x${ARCH}" == "xarmv7l" ] ; then
MKIMAGE=$(which mkimage 2> /dev/null)
INITRAMFS=$(sudo which update-initramfs 2> /dev/null)


if [ "x${MMC}" == "x" ] ; then
        MMC="/dev/mmcblk0p1"
fi

echo "Mounting Fat partition"
sudo mkdir -p /tmp/boot
sudo umount ${MMC} &> /dev/null
sudo mount ${MMC} /tmp/boot
sudo touch /tmp/boot/ro && sudo rm -f /tmp/boot/ro || sudo mount -o remount,rw /tmp/boot

MMC_TEST=$(mount | grep $MMC | awk '{print $3}')
if [ "x${MMC_TEST}" == "x/tmp/boot" ] ; then

        HAS_MKIMAGE=1
        if [ "x${MKIMAGE}" == "x" ] ; then
                unset HAS_MKIMAGE
        fi

        if [ "x${INITRAMFS}" == "x" ] ; then
                echo "Installing Required Packages: initramfs-tools"
                sudo apt-get install -y initramfs-tools
        fi

        #echo "Downloading Recommended Kernel"
        #sudo mkdir -p /tmp/deb
        #sudo wget -c --directory-prefix=/tmp/deb http://rcn-ee.net/deb/precise-armhf/v3.0.40-x4/linux-image-3.0.40-x4_1.0precise_armhf.deb

        echo "Installing linux-image"
        sudo dpkg -i $1

        if [ -f /boot/vmlinuz-$VER ] ; then

                if [ -f /tmp/boot/uImage ] ; then
                        echo "Backing up uImage as uImage_old..."
                        sudo mv -v /tmp/boot/uImage /tmp/boot/uImage_old
                fi

                if [ -f /tmp/boot/zImage ] ; then
                        echo "Backing up zImage as zImage_old..."
                        sudo mv -v /tmp/boot/zImage /tmp/boot/zImage_old
                fi

                if [ -f /tmp/boot/uInitrd ] ; then
                        echo "Backing up uInitrd as uInitrd_old..."
                        sudo mv -v /tmp/boot/uInitrd /tmp/boot/uInitrd_old
                fi

                if [ -f /tmp/boot/initrd.img ] ; then
                        echo "Backing up initrd.img as initrd.img_old..."
                        sudo mv -v /tmp/boot/initrd.img /tmp/boot/initrd.old
                fi

                if [ "${HAS_MKIMAGE}" ] ; then
                        echo "Creating uImage from vmlinuz"
                        if [ -f /tmp/boot/SOC.sh ] ; then
                                load_addr=$(cat /tmp/boot/SOC.sh | grep load_addr | awk -F"=" '{print $2}')
                        else
                                load_addr=0x80008000
                        fi
                        sudo mkimage -A arm -O linux -T kernel -C none -a ${load_addr} -e ${load_addr} -n $VER -d /boot/vmlinuz-$VER /tmp/boot/uImage
                fi

                if [ ! -f /boot/initrd.img-$VER ] ; then
                        echo "Creating /boot/initrd.img-${VER}"
                        sudo update-initramfs -c -k $VER
                fi

                if [ "${HAS_MKIMAGE}" ] ; then
                        echo "Creating uInitrd"
                        sudo mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs -d /boot/initrd.img-$VER /tmp/boot/uInitrd
                fi

                ls -lh /tmp/boot/*

                sudo cp -v /boot/vmlinuz-$VER /tmp/boot/zImage
                sudo cp -v /boot/initrd.img-$VER /tmp/boot/initrd.img

                sudo umount /tmp/boot

        else
                echo "FAILURE TO EXTRACT [/boot/vmlinuz-${VER}] with [sudo dpkg -i /tmp/deb/linux-image-${VER}_1.0precise_armhf.deb]"
                echo "Stopping script to save current image.. double check the install-me script is for your distro-arch"
        fi

        echo "Please Reboot"
else
        echo "Could Not mount MMC Directory"
fi
else
echo "Sorry Not Implemented yet, run this script directly on armv7l target"
fi

