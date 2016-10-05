FROM debian:jessie
MAINTAINER John Morris <john@zultron.com>

###################################################################
# Generic apt configuration

ENV TERM dumb

# apt config:  silence warnings and set defaults
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
ENV LC_ALL C.UTF-8
ENV LANGUAGE C.UTF-8
ENV LANG C.UTF-8

# turn off recommends on container OS and proot OS
RUN echo 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' > \
            /etc/apt/apt.conf.d/01norecommend && \
    mkdir -p ${ROOTFS}/etc/apt/apt.conf.d && \
    echo 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' > \
            ${ROOTFS}/etc/apt/apt.conf.d/01norecommend

# use stable Debian mirror
RUN sed -i /etc/apt/sources.list -e 's/httpredir.debian.org/ftp.debian.org/'

###################################################################
# Configure 3rd-party apt repos and update the OS

# install apt-transport-https for packagecloud.io
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates

# add emdebian package archive
ADD emdebian-toolchain-archive.key /tmp/
RUN apt-key add /tmp/emdebian-toolchain-archive.key && \
    echo "deb http://emdebian.org/tools/debian/ jessie main" > \
        /etc/apt/sources.list.d/emdebian.list

# add Machinekit package archive

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 43DDF224
RUN echo 'deb http://deb.machinekit.io/debian jessie main' > \
        /etc/apt/sources.list.d/machinekit.list

# update Debian OS
RUN apt-get update && \
    apt-get -y upgrade

###################################################################
# Install basic packages

# Utilities
RUN apt-get -y install \
	locales \
	git \
	bzip2 \
	sharutils \
	net-tools \
	time \
	help2man \
	xvfb \
	xauth \
	python-sphinx \
	wget

# Dev tools
RUN apt-get install -y \
	build-essential \
	devscripts \
	fakeroot \
	equivs \
	lsb-release \
	less \
	python-debian \
	libtool \
	ccache \
	autoconf \
	quilt 

# Add armhf foreign architecture
RUN dpkg --add-architecture armhf && \
        apt-get update

# Cross-build toolchain and qemulator
RUN apt-get -y install \
        crossbuild-essential-armhf \
        qemu-user-static

###################################################################
# Install Machinekit depndencies

# Machinekit build-arch deps
RUN apt-get install -y \
        automake \
	cython \
	psmisc \
	python-tk \
	kmod \
	python-setuptools \
	uuid-runtime \
	protobuf-compiler \
	python-protobuf \
	python-simplejson \
	libtk-img \
	python-pyftpdlib

# Machinekit host-arch deps
RUN apt-get install -y \
        libgl1-mesa-dev:armhf \
        libglu1-mesa-dev:armhf \
        libgtk2.0-dev:armhf \
        libmodbus-dev:armhf \
        libncurses-dev:armhf \
        libreadline-dev:armhf \
        libusb-1.0-0-dev:armhf \
        libxmu-dev:armhf \
        libxmu-headers:armhf \
        libxaw7-dev:armhf \
        libzmq3-dev:armhf \
        libczmq-dev:armhf \
        libjansson-dev:armhf \
        libwebsockets-dev:armhf \
        liburiparser-dev:armhf \
        libssl-dev:armhf \
        uuid-dev:armhf \
        libavahi-client-dev:armhf \
        libprotobuf-dev:armhf \
        libprotoc-dev:armhf \
        libboost-thread-dev:armhf \
        libxenomai-dev:armhf \
        tcl8.6-dev:armhf \
        tk8.6-dev:armhf \
        libboost-serialization-dev:armhf

# Machinekit hairy dep:  libboost-python-dev:armhf
#
# Unproblematic deps of libboost-python-dev:armhf
RUN apt-get install -y \
        libpython2.7:armhf \
        libpython2.7-dev:armhf \
        libpython2.7-minimal:armhf \
	libpython-dev:armhf \
        libpython-stdlib:armhf \
        libboost-python1.55.0:armhf
# Problematic deps want to reinstall the matching build-arch pkgs:
# python{2.7,}-minimal:armhf python{2.7,}:armhf  python{2.7,}-dev:armhf
#
# Force-install libboost-python-dev:armhf
RUN mkdir /tmp/pkg-downloads && cd /tmp/pkg-downloads && \
        apt-get download \
            libboost-python1.55-dev:armhf libboost-python-dev:armhf && \
        dpkg -i --force-depends *.deb

# Machinekit host-arch deps to skip:
# - python-zmq:armhf:  wants to reinstall python:armhf

# Now running `debian/configure -prxt 8.6 && dpkg-buildpackage -uc -us
# -a armhf -B` should show the following missing deps:
#
# dpkg-checkbuilddeps: Unmet build dependencies: python (>= 2.6.6-3~)
#    python-dev (>= 2.6.6-3~) cython (>= 0.19) python-tk python-zmq (>=
#    14.0.1) python-protobuf (>= 2.4.1) python-simplejson libtk-img

###########################################
# Set up environment
#
# Customize the following to match the user's environment

# Set up user ID inside container to match your ID
ENV USER jman
ENV UID 1000
ENV GID 1000
ENV HOME /home/${USER}
ENV SHELL /bin/bash
ENV PATH /usr/lib/ccache:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin
RUN echo "${USER}:x:${UID}:${GID}::${HOME}:${SHELL}" >> /etc/passwd
RUN echo "${USER}:x:${GID}:" >> /etc/group

# Customize the run environment to your taste
# - bash prompt
# - 'ls' alias
RUN sed -i /etc/bash.bashrc \
    -e 's/^PS1=.*/PS1="\\h:\\W\\$ "/' \
    -e '$a alias ls="ls -aFs"'

# Install and configure sudo, passwordless for everyone
RUN apt-get -y install sudo
RUN echo "ALL	ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
###################################################################
# Install extra packages

# add packagecloud cli and prune utility
RUN	apt-get install -y python-restkit rubygems
RUN	gem install package_cloud --no-rdoc --no-ri
ADD	PackagecloudIo.py prune.py /usr/bin/

##################################################################

# # add machinekit.io repository
# RUN echo "deb http://deb.machinekit.io/debian ${SUITE} main" \
#          > ${ROOTFS}/etc/apt/sources.list.d/machinekit.list
# # linux-libc-dev=4.1.19-rt22mah-2 breaks cross-compiler installation
# RUN echo "Package: linux-libc-dev\nPin: version 4.1*\nPin-Priority: -10" \
#     > /etc/apt/preferences.d/01pin-linux-libc-dev.pref
# RUN apt-key adv --keyserver hkp://keys.gnupg.net \
#         --recv-key 43DDF224
# RUN apt-get update

