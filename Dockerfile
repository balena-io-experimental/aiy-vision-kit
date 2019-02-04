# Built using https://github.com/google/aiyprojects-raspbian/blob/aiyprojects/HACKING.md
FROM balenalib/rpi-raspbian

# Install some utilities we will need
RUN apt-get update && apt-get install apt-transport-https build-essential cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev libffi-dev python3-dev python3-pip python3-setuptools wget unzip jq

# Set our working directory
WORKDIR /usr/src/app

# switch on systemd init system in container
ENV INITSYSTEM on
# We load some modules to access the vision bonnet. Need udev for some dynamic dev nodes
ENV UDEV=1

# Add aiy debian apt repos
RUN echo "deb https://dl.google.com/aiyprojects/deb stable main" | sudo tee /etc/apt/sources.list.d/aiyprojects.list
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
RUN apt-get update

# Grab aiy deb packages
# By default the deb packages fetch kernel headers from raspbian. We need to use our balenaOS ones.
# We manually extract the DKMS deb packages and compile the modules

# Extract the aiy vision bonnet mcu modules. We compile on device based on that os version
RUN apt-get download aiy-dkms
RUN mkdir aiy-dkms && mv aiy-dkms*.deb aiy-dkms && cd aiy-dkms && ar x aiy-dkms*.deb && tar -xf data.tar.xz

# Extract the aiy vision bonnet myriad chip kernel module. We compile on device based on that os version
RUN apt-get download aiy-vision-dkms
RUN mkdir aiy-vision-dkms && mv aiy-vision-dkms*.deb aiy-vision-dkms && cd aiy-vision-dkms && ar x aiy-vision-dkms*.deb && tar -xf data.tar.xz

# Grab aiy vision python libraries
RUN apt-get download aiy-models aiy-python-wheels

# Run the face detection example demo
ADD run.sh /usr/src/app/run.sh
CMD ["/usr/src/app/run.sh"]
