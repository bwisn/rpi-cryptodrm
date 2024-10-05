# rpi-cryptodrm

**rpi-cryptodrm** is a tool that simplifies setting up Digital Rights Management (DRM) on Raspberry Pi devices using disk encryption (LUKS2). This project leverages the Raspberry Pi's unique CPU serial number as a hardware-based authentication mechanism, ensuring that the SD card can only be decrypted and accessed on the original device.

## Features

- Rootfs encryption using LUKS2 .
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
2. Check the SD card device (in my case it is ```/dev/sde```)
3. Download the script and run it with the SD card device and CPU serial number passed as arguments
```bash
wget https://raw.githubusercontent.com/bwisn/rpi-cryptodrm/refs/heads/master/host-encryptcard.sh
sudo bash host-encryptcard.sh [device] [serial]
# sudo bash host-encryptcard.sh /dev/sde 000000000aaaaabbbbccc
```
4. Insert the SD card back to the RPi

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to enhance the project.

## License

This project is licensed under the MIT License. See the LICENSE file for details.