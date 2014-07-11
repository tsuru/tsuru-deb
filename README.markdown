#tsuru-deb

This repository contains sources for [Tsuru](http://tsuru.io)'s Debian packages.

##Install packages from repository

###Ubuntu precise (12.04 LTS) / Ubuntu trusty (14.04 LTS)

The simplest way to use is the official vagrant provision. Install [vagrant](http://www.vagrantup.com/downloads.html) and your favorite vagrant provider before running these commands:

    % git clone https://github.com/tsuru/tsuru-bootstrap.git
    % cd tsuru-bootstrap
    % vagrant up

Now sit down and for a cup of tea, you'll notice that ``tsuru`` is installed automatically.

Else, you can always use these packages on Ubuntu via [Tsuru ppa](https://launchpad.net/~tsuru/+archive/ppa):

	% sudo apt-add-repository ppa:tsuru/ppa
	% sudo apt-get update
	% sudo apt-get install tsuru

### Debian wheezy (7.x stable)

We are still working on to support Debian wheezy. But you can install it manually now.

At first, ensure you have the official "wheezy-backports" repository in your APT source list.
The whole stuff includes ``tsuru`` and ``docker``, requires backports packages to be installed.

Afterwards, you should build all packages locally. We recommend you to build them under Ubuntu
trusty. Because Debian wheezy may not compatible with some building requirements.

Set ``VERSIONS`` variable may help you to accelerate the building procedures. If you do not need
packages for other distributions:

    % echo "VERSIONS = wheezy" >> variables.local.mk

After the building, you can find a local repository named ``./localrepo``. Add these lines to
Debian wheezy APT source list:

    deb file:///path/to/localrepo wheezy-backports main
    deb-src file:///path/to/localrepo wheezy-backports main

Run ``apt-get update``, you can install ``tsuru`` for Debian:

	% sudo apt-get update
	% sudo apt-get install tsuru

##Building locally

###Dependencies

In order to install the necessary dependencies, on Ubuntu, run with a sudoer
user:

	% make prepare

``golang>=1.1`` is required to be available in your APT sources. So we recommend you to
build locally under Ubuntu trusty (14.04, or later) or Debian jessie (8.x, or later).

###Building source packages

In order to build source package(s) for one software, run ``make <package-name>.buildsrc``.
For instance:

	% make tsuru-server.buildsrc

To build source packages for all softwares, run:

	% make buildsrc

The result package(s) is/are located in directory ``./<package-name>.buildsrc``.

###Building binary packages

To build all packages just run:

	% make builddeb

Or you just want to build one package, run ``make <package-name>.builddeb``.
For instance:

	%make tsuru-server.builddeb 

The result package(s) is/are located in directory ``./<package-name>.builddeb``.

You do not need to build the source packages before binary building.
The ``make`` command will build the necessary source packages for you.

The binary(.deb) packages building process is depend on ``cowbuilder`` - an wrapper with super
powers to pbuilder, already installed with ``prepare`` target and initialized automatically.
But you can still initialize ``cowbuilder`` environments by:

	% make builder

It will create all ubuntu & debian releases environments supported by Tsuru team.

###Uploading source packages to PPA (only Ubuntu distributions)

You can upload any signed source packages to your own PPA, just use:

	% PPA="tsuru/ppa" make tsuru-server.upload

You do not need to build the source packages before uploading.
The ``make`` command will build the necessary source packages for you.

Notice: launchpad.net requires source packages only.
It will build all binary .deb packages on its cloud after uploading.
And do not try to upload Debian distribution packages, it will simply fail.

###Hosting local repository (Ubuntu & Debian)

Because PPA only supports Ubuntu, we introduced ``reprepro`` to manage and host both Ubuntu
and Debian packages. It will be initialized with ``cowbuilder``. Or you can initialize it
separately as your wish. Just run:

	% make localrepo

And you can find your local repository at ``./localrepo``.

After initialization, you can build and import your binary packages into ``./localrepo`` just
by run ``make <package-name>.builddeb``.

## Custom variables

All variables defined in ``variables.mk`` can be overrided by variables with the same name defined
in ``variables.local.mk``. So you can simply custom them in the local file.

### Required custom variables

Variable ``GPGID`` is required for the local repository and/or PPA repository.
You can generate a GPG key with ``gnupg``:

	% sudo apt-get install gnupg
	% gpg --gen-key

After finding out your GPG id or GPG email, you can specify the ``GPGID`` in ``variables.local.mk``:

	GPGID = for@example.com

Or just passing the variable when you run ``make``:

	% GPGID=for@example.com make some_stuff

### Recommended custom variables

We recommended you to custom your Debian & Ubuntu mirror repository in ``variables.local.mk``
to make the building process faster. For example, on an EC2 instance:

	DEBIAN_MIRROR = http://cloudfront.debian.net/debian
	UBUNTU_MIRROR = http://us-west-2.ec2.archive.ubuntu.com/ubuntu

Variable ``DEBEMAIL`` and ``DEBFULLNAME`` is required if you want to custom the signature in
``debian/changelog``:

	export DEBEMAIL = johndue@example.com
	export DEBFULLNAME = John Due 

## Maintainance

### Bump versions
If a package is old, you can upgrade it following these steps:

1. Define env vars ``DEBFULLNAME`` and ``DEBEMAIL`` in ``~/.profile`` and source it.
   Else, you can skip this step and specify these vars in next step.

2. Upgrade files in the ``<package-name>-deb/debian`` directory, adjust ``debian/changelog``:

	    % cd golang-deb
	    % DEBFULLNAME=<fullname> DEBEMAIL=<email> dch -D unstable

    You should always use "unstable" as the distribution code
    the *.builddeb target will change it to proper code automatically

3. Bump the TAG_* variable defined in ``variables.mk``:

	TAG_golang = 1.3

4. Build source package or binary package if you needed.
