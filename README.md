# aiy-vision-kit
Example project using the Google AIY Vision Kit

The [Google AIY Vision kit](https://aiyprojects.withgoogle.com/vision/) is an interesting piece of hardware. It has a Pi 0 HAT that has the Intel Movidius Myriad neural compute chip. A key feature of the HAT is that it directly taps into the camera stream instead of relying on the Pi to fetch the video and then copy it to the compute chip for Machine Learning.

Google provides a customized Raspbian image alongside the kit. The Raspbian image comes with custom firmware for the myriad HAT, custom kernel modules for the HAT and some example modules.

Google provides some [documentation](https://github.com/google/aiyprojects-raspbian/blob/aiyprojects/HACKING.md) if someone wants to use the vision kit with a custom OS.
This repository sets up the AIY Vision Kit so that it can be used using balenaOS.

The `Dockerfile` and `run.sh` have quite a few comments to follow what is going on.

You will need the following variables in your device/fleet configuration
- `RESIN_HOST_CONFIG_gpu_mem` : `128`
- `RESIN_HOST_CONFIG_start_x` : `1`

#### Some notes:
Google provides DKMS deb packages for the kernel modules needed by the HAT. By default they compile using the raspbian kernel headers. We needed to extract the kernel sources and compile the module using the balenaOS kernel headers.

The firmware needed to be present in the /lib/firmware/ folder which is read-only by default in balenaOS. We read-write mount that folder temporarily while installing the firmware.
