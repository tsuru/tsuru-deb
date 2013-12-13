DEFINED_VERSION=precise
VERSIONS=precise quantal raring saucy
SHELL=/bin/bash

comma:= ,
empty:= 
space:= $(empty) $(empty)
pipe:= \|

GOPATH=$(shell echo $$PWD)

all:
	@exit 0

clean:
	git clean -dfX

local_setup:
	sudo apt-add-repository -y ppa:tsuru/golang
	sudo apt-get install golang debhelper devscripts git mercurial ubuntu-dev-tools cowbuilder -y
	mkdir /tmp/gopath
	GOPATH=/tmp/gopath go get github.com/kr/godep
	sudo mv /tmp/gopath/bin/godep /usr/bin
	rm -rf /tmp/gopath

cowbuilder_create:
	for version in $(VERSIONS); do cowbuilder-dist $$version create ; done

cowbuilder_build:
	if [ -f /tmp/ppa.sh ]; then rm /tmp/ppa.sh; fi
	echo "/usr/bin/apt-get install -y python-software-properties software-properties-common" >> ppa.sh
	echo "/usr/bin/add-apt-repository -y ppa:tsuru/ppa" >> /tmp/ppa.sh
	echo "/usr/bin/add-apt-repository -y ppa:tsuru/lvm2" >> /tmp/ppa.sh
	echo "/usr/bin/add-apt-repository -y ppa:tsuru/golang" >> /tmp/ppa.sh
	for version in $(VERSIONS); do \
	    cowbuilder-dist $$version execute --save --override-config /tmp/ppa.sh && \
	    cowbuilder-dist $$version update --override-config && \
	    cowbuilder-dist $$version build --override-config *$${version}*.dsc; \
	done
	
upload:
	for file in *.changes; do debsign $$file; done; unset file
	for file in *.changes; do dput ppa:tsuru/ppa $$file; done

_download:
	if [ ! $$TAG ]; then echo "TAG env var must be set... use: TAG=<value> make $(TARGET)"; exit 1; fi
	if [ -d $(TARGET)-$$TAG ]; then rm -rf $(TARGET)-$$TAG; fi
	if [ -f $(TARGET)_$${TAG}.orig.tar.gz ]; then rm $(TARGET)_$${TAG}.orig.tar.gz; fi
	mkdir $(TARGET)-$$TAG
	pushd . && cd $(TARGET)-$$TAG && pushd . \
	export GOPATH=$$PWD && go get -v -d -u github.com/dotcloud/tar && go get -v -u -d github.com/globocom/tsuru/... && \
	export GOPATH=$$PWD && cd src/github.com/globocom/tsuru && git checkout $$TAG && godep restore ./... && \
	rm -rf src/github.com/globocom/tsuru/src && \
	popd && find . \( -iname ".git*" -o -iname "*.bzr" -o -iname "*.hg" \)  && \
	popd && tar zcvf $(TARGET)_$${TAG}.orig.tar.gz $(TARGET)-$$TAG
	rm -rf $(TARGET)-$$TAG

_build:
	if [ -f debian/changelog.bkp ]; then rm debian/changelog.bkp; fi
	sed -i.bkp -e 's/\($(subst $(space),$(pipe),$(VERSIONS))\)/$(VERSION)/g' debian/changelog
	debuild --no-tgz-check -S -sa -us -uc
	mv debian/changelog.bkp debian/changelog

_do:
	for version in $(VERSIONS); do make VERSION=$$version CMD=$(TARGET) -C $(TARGET)-deb -f ../Makefile _build; done

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

lxc-docker:
	if [ -d lxc-docker-$$TAG ]; then rm -rf lxc-docker-$$TAG; fi 
	if [ -d docker-$$TAG ]; then rm -rf docker-$$TAG; fi
	curl -L -o lxc-docker-$$TAG.orig.tar.gz https://github.com/dotcloud/docker/archive/v$$TAG.tar.gz
	tar zxvf lxc-docker-$$TAG.orig.tar.gz && rm lxc-docker-$$TAG.orig.tar.gz
	mv docker-$$TAG lxc-docker-$$TAG
	pushd . && cd lxc-docker-$$TAG && GOPATH=$$PWD go get -d -v -u github.com/dotcloud/docker/... && popd
	pushd . && cd lxc-docker-$$TAG/src/github.com/dotcloud/docker && git fetch --tags && git checkout v$$TAG && popd
	tar zcvf lxc-docker_$$TAG.orig.tar.gz lxc-docker-$$TAG
	rm -rf lxc-docker-$$TAG
	make TARGET=$@ _do

golang:
	if [ -f golang_1.2.orig.tar.gz ]; then rm golang_1.2.orig.tar.gz; fi
	curl -L -o golang_1.2.orig.tar.gz https://go.googlecode.com/files/go1.2.src.tar.gz
	make TARGET=$@ _do

%:
	make TARGET=$@ _download
	#make TARGET=$@ _do
