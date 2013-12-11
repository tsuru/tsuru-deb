# Ubuntu package Makefile
#
# Dependencies:  debhelper autotools-dev devscripts golang-stable
# Notes:
# Use 'make ubuntu' to create the ubuntu package and push it to stating PPA by
# default. To push to production, set PUBLISH_PPA=1 before doing 'make ubuntu'
# GPG_KEY environment variable needs to contain a GPG private key for package
# to be signed and uploaded to docker PPA. If GPG_KEY is not defined,
# make ubuntu will create docker package and exit with status code 2

PKG_NAME=lxc-docker

all:
	# Compile docker. Used by dpkg-buildpackage.
	cd docker && GOPATH=${CURDIR} CGO_ENABLED=0 go build -a -ldflags '-d -w'

install:
	# Used by dpkg-buildpackage
	mkdir -p ${DESTDIR}/usr/bin
	mkdir -p ${DESTDIR}/etc/init
	mkdir -p ${DESTDIR}/DEBIAN
	install -m 0755 docker/docker ${DESTDIR}/usr/bin
	install -o root -m 0644 debian/docker.upstart ${DESTDIR}/etc/init/docker.conf
