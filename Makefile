DEFINED_VERSION=precise
VERSIONS="precise quantal raring saucy"
UBUNTU_MIRRORS="deb http://ppa.launchpad.net/juju/golang/ubuntu UBUNTU_VERSION main | deb http://ppa.launchpad.net/tsuru/ppa/ubuntu UBUNTU_VERSION main"
SHELL=/bin/bash

GOPATH=$(shell echo $$PWD)

all:
	@exit 0

clean:
	git clean -dfX

local_setup:
	sudo apt-add-repository -y ppa:juju/golang
	sudo apt-get install golang debhelper devscripts git mercurial ubuntu-dev-tools cowbuilder -y
	mkdir /tmp/gopath
	GOPATH=/tmp/gopath go get github.com/kr/godep
	sudo mv /tmp/gopath/bin/godep /usr/bin
	rm -rf /tmp/gopath

cowbuilder_create:
	for version in "$(VERSIONS)"; do cowbuilder-dist $$version create ; done

cowbuilder_build:
	# OTHERMIRROR=$(subst UBUNTU_VERSION,$$version,$(UBUNTU_MIRRORS)) cowbuilder-dist $$version update --override-config &&
	if [ -f ppa.sh ]; then rm ppa.sh; fi
	echo "/usr/bin/apt-get install -y python-software-properties" >> ppa.sh
	echo "/usr/bin/add-apt-repository -y ppa:tsuru/ppa" >> ppa.sh
	echo "/usr/bin/add-apt-repository -y ppa:tsuru/lvm2" >> ppa.sh
	echo "/usr/bin/add-apt-repository -y ppa:juju/golang" >> ppa.sh
	for version in "$(VERSIONS)"; do \
	    cowbuilder-dist $$version execute --save --override-config ppa.sh && \
	    cowbuilder-dist $$version update --override-config && \
	    cowbuilder-dist $$version build --override-config *$${version}*.dsc; \
	done
	
upload:
	for file in *.changes; do debsign $$file; done; unset file
	for file in *.changes; do dput ppa:tsuru/ppa $$file; done

_download:
	if [ ! $$TAG ]; then TAG="master"; fi
	export GOPATH=$$PWD && go get -v -u -d github.com/globocom/tsuru/...
	export GOPATH=$$PWD && cd src/github.com/globocom/tsuru && git checkout $$TAG && godep restore ./...
	rm -rf src/github.com/globocom/tsuru/src

_build:
	sed -i.bkp -e 's/$(subst " ","|",$(VERSIONS))/$(VERSION)/g' debian/changelog
	debuild --no-tgz-check -S -sa -us -uc
	mv debian/changelog.bkp debian/changelog

_do:
	for version in "$(VERSIONS)"; do make VERSION=$$version CMD=$(TARGET) -C $(TARGET)-deb -f ../Makefile _build; done

gandalf-server:
	cd gandalf-server-deb && GOPATH=$$PWD go get -d github.com/globocom/gandalf/...
	make TARGET=$@ _do

nodejs:
	make TARGET=$@ _do

node-hipache:
	make TARGET=$@ _do

docker-registry:
	cd docker-registry-deb && GOPATH=$$PWD go get -d github.com/fsouza/docker-registry/contrib/golang_impl
	make TARGET=$@ _do

tsuru-mongoapi:
	cd tsuru-mongoapi-deb && GOPATH=$$PWD go get -d github.com/globocom/mongoapi
	make TARGET=$@ _do

docker:
	if [ -d lxc-docker-$$TAG ]; then rm -rf lxc-docker-$$TAG; fi 
	if [ -d docker-$$TAG ]; then rm -rf docker-$$TAG; fi
	curl -L -o lxc-docker-$$TAG.orig.tar.gz https://github.com/dotcloud/docker/archive/v$$TAG.tar.gz
	tar zxvf lxc-docker-$$TAG.orig.tar.gz && rm lxc-docker-$$TAG.orig.tar.gz
	mv docker-$$TAG lxc-docker-$$TAG
	pushd . && cd lxc-docker-$$TAG && GOPATH=$$PWD go get -d -v -u github.com/dotcloud/docker/... && popd
	tar zcvf lxc-docker_$$TAG.orig.tar.gz lxc-docker-$$TAG

%:
	make -C $@-deb -f ../Makefile _download
	make TARGET=$@ _do
