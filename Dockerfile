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

# make sure linux-libc-dev isn't installed from the MK repo; because
# that kernel version doesn't match mainline kernels, the
# `linux-libc-dev` package will have different versions across
# architectures, and therefore conflict
RUN echo "Package: linux-libc-dev\nPin: version 3.*\nPin-Priority:" \
        "1001\n\nPackage: linux-libc-dev:armhf\nPin: " \
        "version 3.*\nPin-Priority: 1001" > \
        /etc/apt/preferences.d/10pin-linux-libc-dev

# update Debian OS
RUN apt-get update && \
    apt-get -y upgrade

###################################################################
# Install generic packages

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
	wget \
        sudo \
	lftp

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

# Add packagecloud cli and prune utility
RUN	apt-get install -y python-restkit rubygems
RUN	gem install package_cloud --no-rdoc --no-ri
ADD	PackagecloudIo.py prune.py /usr/bin/

# Add armhf foreign architecture
RUN dpkg --add-architecture armhf
RUN apt-get update

# Cross-build toolchain and qemulator
# For some reason, apt-get chokes without explicit `linux-libc-dev:armhf`
RUN apt-get -y install \
        crossbuild-essential-armhf \
        qemu-user-static \
	linux-libc-dev:armhf

###################################################################
# Install Machinekit dependency packages

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

# libboost-python-dev:armhf is a problematic Machinekit build dep that
# wants to reinstall the matching build-arch pkgs
# python{2.7,}{-minimal,-dev,}:armhf
#
# Unproblematic deps of libboost-python-dev:armhf
RUN apt-get install -y \
        libpython2.7:armhf \
        libpython2.7-dev:armhf \
        libpython2.7-minimal:armhf \
	libpython-dev:armhf \
        libpython-stdlib:armhf \
        libboost-python1.55.0:armhf

# The package itself needs to be force-installed, but that breaks apt,
# so only install it at the end.

# Download packages and force-install libboost-python-dev:armhf; after
# this, `apt-get` will be broken; unbreak by removing problem packages
# again with `force-install -r`
RUN mkdir /tmp/pkg-downloads && \
    cd /tmp/pkg-downloads && \
    apt-get download libboost-python1.55-dev:armhf libboost-python-dev:armhf
ADD force-install.sh /usr/bin/force-install
RUN force-install -i

# Machinekit host-arch deps to skip:
# - python-zmq:armhf:  wants to reinstall python:armhf

# After `force-install -i`, force-adding libboost-python-dev:armhf,
# running `debian/configure -prxt 8.6 && dpkg-buildpackage -uc -us -a
# armhf -B` should show the following missing deps:
#
# dpkg-checkbuilddeps: Unmet build dependencies: python (>= 2.6.6-3~)
#    python-dev (>= 2.6.6-3~) cython (>= 0.19) python-tk python-zmq (>=
#    14.0.1) python-protobuf (>= 2.4.1) python-simplejson libtk-img

###########################################
# Set up environment
#
# Customize the following to match the user's environment

# Set up user ID inside container to match your ID
ENV USER travis
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

# Configure sudo, passwordless for everyone
RUN echo "ALL	ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
