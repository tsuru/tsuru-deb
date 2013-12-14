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

In order to build a source package locally, just run ``TAG=<release> make <package-name>``.
You should use an additional "TAG" env var to use one specific git release. For instance:

	% TAG=0.2.12 make tsuru-server

####Generating binary packages

To create binary packages, you gonna need cowbuilder - an wrapper with super
powers to pbuilder, already installed with ``local_setup`` target. Just run:

	% make cowbuilder_create

It will create all ubuntu releases environments supported by Tsuru team. After that,
to build all packages just run:

	% make cowbuilder_build

####Uploading packages

To sign and upload packages to your own PPA, just use:

	% PPA="tsuru/ppa" make upload

It will sign all packages builded and upload to a custom PPA defined on PPA env var
