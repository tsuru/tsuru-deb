#tsuru-deb

This repository contains sources for [Tsuru](http://tsuru.io)'s Debian packages.

You can use these packages on Ubuntu via [Tsuru ppa](https://launchpad.net/~tsuru/+archive/ppa):

	% sudo apt-add-repository ppa:tsuru/ppa
	% sudo apt-get update
	% sudo apt-get install tsuru

##Building locally

###Dependencies

In order to install the necessary dependencies, on Ubuntu, run with a sudoer
user:

	% make local_setup

###Building packages

In order to build a source package locally, just run ``make <package-name>``.
For instance:

	% make tsuru

Makefile doesn't contain any rule for generating binary packages, just source
packages. You can build a binary package invoking ``debuild`` directly.
