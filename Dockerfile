FROM debian:jessie
MAINTAINER John Morris <john@zultron.com>

ENV TERM dumb

# apt config:  silence warnings and set defaults
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
ENV LC_ALL C 
ENV LANGUAGE C
ENV LANG C

# turn off recommends on container OS and proot OS
RUN echo 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' > \
            /etc/apt/apt.conf.d/01norecommend && \
    mkdir -p ${ROOTFS}/etc/apt/apt.conf.d && \
    echo 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' > \
            ${ROOTFS}/etc/apt/apt.conf.d/01norecommend

# use stable Debian mirror
RUN sed -i /etc/apt/sources.list -e 's/httpredir.debian.org/ftp.debian.org/'

# add emdebian package archive
ADD emdebian-toolchain-archive.key /tmp/
RUN apt-key add /tmp/emdebian-toolchain-archive.key && \
    echo "deb http://emdebian.org/tools/debian/ jessie main" >> \
        /etc/apt/sources.list.d/emdebian.list

# update Debian root
RUN	apt-get update && \
	apt-get -y upgrade

# install required dependencies
RUN	apt-get -y install \
	    debootstrap \
	    multistrap \
	    locales \
	    rubygems \
	    git \
	    bzip2 \
	    ca-certificates \
	    wget
#	    proot \

# patch debootstrap as /proc cannot be mounted under proot
RUN	sed -i 's/in_target mount -t proc/#in_target mount -t proc/g' \
	    /usr/share/debootstrap/functions

# install native cross-compiler and qemulator
RUN dpkg --add-architecture armhf && \
    apt-get update && \
    apt-get -y install \
        crossbuild-essential-armhf \
        qemu-user-static

# add proot-helper script
#ADD proot-helper /bin/

# add packagecloud cli and prune utility
RUN	gem install package_cloud --no-rdoc --no-ri
RUN	apt-get install -y python-restkit
ADD	PackagecloudIo.py prune.py /usr/bin/


# # add machinekit.io repository
# RUN echo "deb http://deb.machinekit.io/debian ${SUITE} main" \
#          > ${ROOTFS}/etc/apt/sources.list.d/machinekit.list
# # linux-libc-dev=4.1.19-rt22mah-2 breaks cross-compiler installation
# RUN echo "Package: linux-libc-dev\nPin: version 4.1*\nPin-Priority: -10" \
#     > /etc/apt/preferences.d/01pin-linux-libc-dev.pref
# RUN apt-key adv --keyserver hkp://keys.gnupg.net \
#         --recv-key 43DDF224
# RUN apt-get update

# # add deps
# RUN apt-get install -y \
#     autoconf automake libboost-python-dev libgl1-mesa-dev libglu1-mesa-dev \
#     libgtk2.0-dev libmodbus-dev libncurses-dev libreadline-dev \
#     libusb-1.0-0-dev libxmu-dev libxmu-headers python python-dev cython \
#     dh-python pkg-config psmisc python-tk libxaw7-dev \
#     libboost-serialization-dev libzmq3-dev libczmq-dev libjansson-dev \
#     libwebsockets-dev python-zmq procps kmod liburiparser-dev libssl-dev \
#     python-setuptools uuid-dev uuid-runtime libavahi-client-dev \
#     libprotobuf-dev protobuf-compiler python-protobuf libprotoc-dev \
#     python-simplejson libtk-img libboost-thread-dev python-pyftpdlib \
#     tcl8.6-dev tk8.6-dev

# # add armhf deps
# RUN apt-get install -y \
#     libgl1-mesa-dev:armhf libglu1-mesa-dev:armhf libgtk2.0-dev:armhf \
#     libzmq3-dev:armhf libczmq-dev:armhf

# Need Multi-Arch libpgm-5.1-0; compile from scratch?
# Dep of libzmq3
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=674610

    # autoconf automake libboost-python-dev \
    #  libmodbus-dev libncurses-dev libreadline-dev \
    # libusb-1.0-0-dev libxmu-dev libxmu-headers python python-dev cython \
    # dh-python pkg-config psmisc python-tk libxaw7-dev \
    # libboost-serialization-dev  libjansson-dev \
    # libwebsockets-dev python-zmq procps kmod liburiparser-dev libssl-dev \
    # python-setuptools uuid-dev uuid-runtime libavahi-client-dev \
    # libprotobuf-dev protobuf-compiler python-protobuf libprotoc-dev \
    # python-simplejson libtk-img libboost-thread-dev python-pyftpdlib \
    # tcl8.6-dev tk8.6-dev

#apt-get -y  -o Apt::Architecture=armhf -o Dir::Etc::TrustedParts=/opt/rootfs/etc/apt/trusted.gpg.d -o Dir::Etc::Trusted=/opt/rootfs/etc/apt/trusted.gpg.d/trusted.gpg -o Apt::Get::Download-Only=true -o Apt::Install-Recommends=false -o Dir=/opt/rootfs/ -o Dir::Etc=/opt/rootfs/etc/apt/ -o Dir::Etc::Parts=/opt/rootfs/etc/apt/apt.conf.d/ -o Dir::Etc::PreferencesParts=/opt/rootfs/etc/apt/preferences.d/ -o APT::Default-Release=* -o Dir::State=/opt/rootfs/var/lib/apt/ -o Dir::State::Status=/opt/rootfs/var/lib/dpkg/status -o Dir::Cache=/opt/rootfs/var/cache/apt/ install  debian-archive-keyring libgl1-mesa-dev libglu1-mesa-dev libgtk2.0-dev libzmq3-dev

# autoconf
# automake
# avahi-daemon
# build-essential
# bwidget
# debhelper
# dh-python
# kmod
# libavahi-client-dev
# libboost-python-dev
# libboost-serialization-dev
# libboost-thread-dev
# libczmq-dev
# libgl1-mesa-dev
# libglib2.0-dev
# libglu1-mesa-dev
# libgtk2.0-dev
# libjansson-dev
# libmodbus-dev
# libncurses-dev
# libprotobuf-dev
# libprotoc-dev
# libreadline-gplv2-dev #libreadline-dev
# libsodium-dev
# libssl-dev
# libtk-img
# libtool
# libudev-dev
# liburiparser-dev
# libusb-1.0-0-dev
# libwebsockets-dev
# libxaw7-dev
# libxmu-dev
# libxmu-headers
# libzmq3-dev
# openssl
# pkg-config
# procps
# protobuf-compiler
# psmisc
# python
# python-avahi
# python-dev
# python-netifaces
# python-nose
# python-protobuf
# python-pyftpdlib
# python-setuptools
# python-simplejson
# python-support
# python-tk
# python-zmq
# uuid-dev
# uuid-runtime
# libxenomai-dev


# ln -s ${ROOTFS}/lib/arm-linux-gnueabihf /lib/
# ln -s ${ROOTFS}/usr/lib/arm-linux-gnueabihf /usr/lib/
# ln -s ${ROOTFS}/usr/include/arm-linux-gnueabihf /usr/include/


# sudo apt-get install libglu1-mesa-dev:armhf libgtk2.0-dev:armhf libmodbus-dev:armhf libusb-1.0-0-dev:armhf libxmu-dev:armhf libxaw7-dev:armhf libboost-serialization-dev:armhf libzmq3-dev:armhf libczmq-dev:armhf libjansson-dev:armhf libwebsockets-dev:armhf liburiparser-dev:armhf libssl-dev:armhf uuid-dev:armhf libavahi-client-dev:armhf libprotobuf-dev:armhf libprotoc-dev:armhf libxenomai-dev:armhf libgl1-mesa-dev:armhf libtk-img:armhf libboost-thread-dev:armhf tcl8.6-dev:armhf tk8.6-dev:armhf


# # Python isn't multi-arch
# # https://wiki.debian.org/Python/MultiArch
# libboost-python-dev python:armhf python-dev:armhf cython:armhf python-tk:armhf python-zmq:armhf python-protobuf:armhf python-simplejson:armhf
