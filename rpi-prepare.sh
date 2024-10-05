#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

for i in 1 2; do
    read -p "[${i}/2] Are you sure you want to prepare the device for encryption? (YES/no): " confirmation
    if [[ "$confirmation" != "YES" ]]; then
        echo "Encryption aborted by user."
        exit 1
    fi
done

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y cryptsetup cryptsetup-initramfs lvm2 busybox initramfs-tools
echo "KEYFILE_PATTERN=/tmp/luks-keyfile" >>/etc/cryptsetup-initramfs/conf-hook
sed -i "s/KEYMAP=n/KEYMAP=y/g" /etc/initramfs-tools/initramfs.conf
sed -i "s/BUSYBOX=auto/BUSYBOX=y/g" /etc/initramfs-tools/initramfs.conf
sed -i '${s/$/ loglevel=4/}' /boot/firmware/cmdline.txt

cat >>/etc/initramfs-tools/scripts/init-premount/luks-keyfile <<EOF
#!/bin/sh
mkdir -p /tmp
cat /proc/cpuinfo | grep Serial | cut -d':' -f2 |  tr -cd '[:alnum:]._-' > /tmp/luks-keyfile
exit 0
EOF

chmod +x /etc/initramfs-tools/scripts/init-premount/luks-keyfile

update-initramfs -c -k $(uname -r)

echo "Your CPU serial number, write it down:"
cat /proc/cpuinfo | grep Serial | cut -d':' -f2 | tr -cd '[:alnum:]._-'
echo
