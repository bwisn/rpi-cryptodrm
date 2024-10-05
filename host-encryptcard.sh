#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

if [ "$#" -ne 2 ]; then
    echo "Usage: sudo ./host-encryptcard.sh <SD card device> <cpu serial number>"
    exit 1
fi

SDCARD_DEV=$1
CPU_SERIAL=$2

if [ ! -b "$SDCARD_DEV" ]; then
    echo "Error: $SDCARD_DEV is not a valid block device."
    exit 1
fi

CPU_SERIAL_SANITIZED=$(echo "$CPU_SERIAL" | tr -cd '[:alnum:]')

if [ -z "$CPU_SERIAL_SANITIZED" ]; then
    echo "Error: Serial number is empty or only contains invalid characters."
    exit 1
fi

for i in 1 2; do
    read -p "[${i}/2] Are you sure you want to ENCRYPT the block device ${SDCARD_DEV}? Partitions: ${SDCARD_DEV}1 ${SDCARD_DEV}2 (YES/no): " confirmation
    if [[ "$confirmation" != "YES" ]]; then
        echo "Encryption aborted by user."
        exit 1
    fi
done

TEMPDIR_MAIN=$(mktemp -d)
TEMPDIR_BACKUP=$(mktemp -d)

mount ${SDCARD_DEV}2 ${TEMPDIR_MAIN}
rsync -axHAWXS --numeric-ids --info=progress2 ${TEMPDIR_MAIN}/ ${TEMPDIR_BACKUP}/
umount ${TEMPDIR_MAIN}

echo -n "${CPU_SERIAL_SANITIZED}" | cryptsetup luksFormat ${SDCARD_DEV}2 \
    --type luks2 \
    --cipher xchacha20,aes-adiantum-plain64 \
    --key-size 256 \
    --hash sha512 \
    --pbkdf argon2i \
    --pbkdf-force-iterations 40 \
    --pbkdf-memory 128000 \
    --pbkdf-parallel 3 \
    --label rpi_cryptroot \
    --subsystem "" \
    --use-random -

echo -n "${CPU_SERIAL_SANITIZED}" | cryptsetup luksOpen ${SDCARD_DEV}2 rpi_cryptroot -

mkfs.ext4 -F -L rootfs /dev/mapper/rpi_cryptroot

mount /dev/mapper/rpi_cryptroot ${TEMPDIR_MAIN}
rsync -axHAWXS --numeric-ids --info=progress2 ${TEMPDIR_BACKUP}/ ${TEMPDIR_MAIN}/

export OLD_ROOTUUID=$(cat ${TEMPDIR_MAIN}/etc/fstab | grep "\-02 " | cut -d' ' -f1 | xargs)
export NEW_ROOTUUID=$(lsblk --noheadings --output "UUID" /dev/mapper/rpi_cryptroot)

sed -i "s/${OLD_ROOTUUID}/UUID=${NEW_ROOTUUID}/g" ${TEMPDIR_MAIN}/etc/fstab

sed -i "s/noatime/lazytime,errors=remount-ro/g" ${TEMPDIR_MAIN}/etc/fstab

export NEW_LUKSUUID=$(lsblk --nodeps --noheadings --output "UUID" ${SDCARD_DEV}2)
echo "rpi_cryptroot UUID=${NEW_LUKSUUID} /tmp/luks-keyfile luks,initramfs" | tee -a ${TEMPDIR_MAIN}/etc/crypttab

mount ${SDCARD_DEV}1 ${TEMPDIR_MAIN}/boot/firmware
for f in dev dev/pts sys proc run; do mount -o bind /$f ${TEMPDIR_MAIN}/$f; done

sed -i "s;${OLD_ROOTUUID};/dev/mapper/rpi_cryptroot;g" ${TEMPDIR_MAIN}/boot/firmware/cmdline.txt

chroot ${TEMPDIR_MAIN} /bin/env -i PATH=/bin:/usr/bin:/sbin:/usr/sbin /sbin/update-initramfs -u -k all

for f in dev/pts dev sys proc run; do umount ${TEMPDIR_MAIN}/$f; done
umount ${TEMPDIR_MAIN}/boot/firmware
umount ${TEMPDIR_MAIN}/
cryptsetup luksClose rpi_cryptroot
sync

rm -rf ${TEMPDIR_MAIN} ${TEMPDIR_BACKUP}
