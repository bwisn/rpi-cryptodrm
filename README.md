# rpi-cryptodrm

**rpi-cryptodrm** is a tool that simplifies setting up Digital Rights Management (DRM) on Raspberry Pi devices using disk encryption (LUKS2). This project leverages the Raspberry Pi's unique CPU serial number as a hardware-based authentication mechanism, ensuring that the SD card can only be decrypted and accessed on the original device.

## Features

- Rootfs encryption using LUKS2.
- Hardware-bound DRM using the Raspberry Pi’s CPU serial number.
- Two-step setup process for ease of use.
- Protects sensitive data on the Raspberry Pi SD card.

## Requirements

- A Raspberry Pi (tested on Raspberry Pi Zero 2W).
- SD card for the Raspberry Pi.
- Linux PC for finalizing encryption setup.
- Root privileges on both the Raspberry Pi and the PC.
- `qemu-arm-static` with binfmt support for running ARM binaries on the host PC.
    
## Setup Instructions

### Stage 1: On the Raspberry Pi
1. Run the script which prepares the device for encryption. Copy the device serial number from the script output.
```bash
wget https://raw.githubusercontent.com/bwisn/rpi-cryptodrm/refs/heads/master/rpi-prepare.sh
sudo bash rpi-prepare.sh
```
2. Power off the RPi gracefully
```bash
sudo poweroff
```
3. Unplug it from the power supply.
   
### Stage 2: On the Linux PC
1. Connect the SD card from RPi to the PC
2. Find the SD card device name (in my case it is ```/dev/sde```)
3. Download the script and run it with the SD card device and CPU serial number passed as arguments
```bash
wget https://raw.githubusercontent.com/bwisn/rpi-cryptodrm/refs/heads/master/host-encryptcard.sh
sudo bash host-encryptcard.sh [device] [serial]
# sudo bash host-encryptcard.sh /dev/sde 000000000aaaaabbbbccc
```
4. Insert the SD card back to the RPi

## Benchmark
Tests were done on RPi Zero 2W equipped with Samsung PRO Endurance 2022 64GB U1 V10 card using sdcard test from ```agnostics``` package.
```
Run 1
prepare-file;0;0;17794;34
seq-write;0;0;18565;4
seq-read;22993;5;0;0
rand-4k-write;0;0;1439;359
rand-4k-read;8117;2029;0;0
Sequential write speed 18565 KB/sec (target 10000) - PASS
Random write speed 359 IOPS (target 500) - FAIL
Random read speed 2029 IOPS (target 1500) - PASS
Run 2
prepare-file;0;0;18450;36
seq-write;0;0;18416;4
seq-read;23009;5;0;0
rand-4k-write;0;0;1433;358
rand-4k-read;7795;1948;0;0
Sequential write speed 18416 KB/sec (target 10000) - PASS
Random write speed 358 IOPS (target 500) - FAIL
Random read speed 1948 IOPS (target 1500) - PASS
Run 3
prepare-file;0;0;18612;36
seq-write;0;0;18397;4
seq-read;23027;5;0;0
rand-4k-write;0;0;1454;363
rand-4k-read;8023;2005;0;0
Sequential write speed 18397 KB/sec (target 10000) - PASS
Random write speed 363 IOPS (target 500) - FAIL
Random read speed 2005 IOPS (target 1500) - PASS
```

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to enhance the project.

## License

This project is licensed under the MIT License. See the LICENSE file for details.