#!/bin/bash

# We have to run some steps that need to run on the device for various reasons

# We need to this on device as the arm builders arch is quirky
# We install these manually as otherwise they will try to install the dependencies
# which are the DKMS deb packages above we just manually compiled.
if ! apt -qq list aiy-python-wheels* | grep -q installed ; then
	dpkg --force-all -i aiy-python-wheels_*.deb aiy-models_*.deb || true
fi

# Get and install the aiy project samples
if [ ! -d AIY-projects-python ]; then
	git clone https://github.com/google/aiyprojects-raspbian.git AIY-projects-python || true
	pip3 install -e AIY-projects-python/src || true
fi

if dpkg -s aiy-vision-firmware | head -n2 | grep -q installed ; then
	# Hack as we need a read-write firmware directory
	mount -o remount,rw /lib/firmware || true
	apt-get install aiy-vision-firmware || true
	mount -o remount,ro /lib/firmware || true
fi

if [ ! -d kernel_modules_headers ]; then
	# Get OS version
	os_version=$(curl -s -X GET --header "Content-Type:application/json"     "$BALENA_SUPERVISOR_ADDRESS/v1/device?apikey=$BALENA_SUPERVISOR_API_KEY" | jq .os_version )
	os_version=$(echo "$os_version"  | tr -d '"' | awk '{print $2}')
	os_version=$(echo "$os_version" | sed -e 's/+/%2B/g')

	# Get kernel module headers for our device as we need to compile the aiy vision modules that are provided as DKMS deb files.
	wget "https://resin-production-img-cloudformation.s3.amazonaws.com/resinos/raspberry-pi/$os_version.dev/kernel_modules_headers.tar.gz"
	tar -xf kernel_modules_headers.tar.gz

	# Compile kernel modules
	make -C kernel_modules_headers M=/usr/src/app/aiy-dkms/usr/src/aiy-* modules
	make -C kernel_modules_headers M=$(realpath /usr/src/app/aiy-vision-dkms/usr/src/aiy-*) modules
fi

# Insert modules
mod=$(find /lib | grep "industrialio.ko$")
insmod "$mod" || true

mod=$(find /usr/src/app | grep "aiy-io-i2c.ko$")
insmod "$mod" || true

mod=$(find /usr/src/app | grep "gpio-aiy-io.ko$")
insmod "$mod" || true

mod=$(find /usr/src/app | grep "pwm-aiy-io.ko$")
insmod "$mod" || true

mod=$(find /usr/src/app | grep "aiy-adc.ko$")
insmod "$mod" || true

mod=$(find /usr/src/app | grep "aiy-vision.ko$")
# Remove vision module to restart the firmware
rmmod aiy-vision || true
insmod "$mod" || true

/usr/src/app/AIY-projects-python/src/examples/vision/face_detection_camera.py
