DEFINED_VERSION=precise
VERSIONS=precise saucy trusty
SHELL=/bin/bash

comma:= ,
empty:= 
space:= $(empty) $(empty)
pipe:= \|

GOPATH=$(shell echo $$PWD)

ifdef DEBEMAIL
	debsign_opt := "-e$$DEBEMAIL"
else
	debsign_opt := ""
endif

all:
	@exit 0

clean:
	git clean -dfX

local_setup:
	sudo apt-get update
	sudo apt-get install -y python-software-properties
	sudo apt-add-repository -y ppa:tsuru/golang
	sudo apt-get update
	sudo apt-get install golang debhelper devscripts git mercurial ubuntu-dev-tools cowbuilder gnupg-agent -y
	if [ ! -d /tmp/gopath ]; then mkdir /tmp/gopath; fi
	GOPATH=/tmp/gopath go get github.com/kr/godep
	sudo mv /tmp/gopath/bin/godep /usr/bin
	rm -rf /tmp/gopath

cowbuilder_create:
	if [ -f /tmp/ppa.sh ]; then rm /tmp/ppa.sh; fi
	echo "/usr/bin/apt-get update" >> /tmp/ppa.sh
	echo "/usr/bin/apt-get install -y python-software-properties software-properties-common" >> /tmp/ppa.sh
	echo "/usr/bin/add-apt-repository -y ppa:tsuru/ppa" >> /tmp/ppa.sh
	echo "/usr/bin/add-apt-repository -y ppa:tsuru/lvm2" >> /tmp/ppa.sh
	echo "/usr/bin/add-apt-repository -y ppa:tsuru/golang" >> /tmp/ppa.sh
	for version in $(VERSIONS); do \
	    cowbuilder-dist $$version create --updates-only && \
	    cowbuilder-dist $$version execute --save --override-config --updates-only /tmp/ppa.sh && \
	    cowbuilder-dist $$version update --override-config --updates-only; \
	done
	rm /tmp/ppa.sh

cowbuilder_build:
	for version in $(VERSIONS); do \
	    cowbuilder-dist $$version build *$${version}*.dsc; \
	done
	
upload:
	if [ ! $$PPA ]; then echo "PPA env var must be set to upload packages... use: PPA=<value> make upload"; exit 1; fi
	eval $$(gpg-agent --daemon) && for file in *.changes; do debsign $(debsign_opt) $$file; done; unset file
	for file in *.changes; do dput ppa:$$PPA $$file; done

_pre_tarball:
	@if [ -f $(TARGET)_ppa_ok ]; then rm $(TARGET)_ppa_ok; fi
	@if [ ! $$TAG ]; then echo "TAG env var must be set... use: TAG=<value> make $(TARGET)"; exit 1; fi
	@if [ -d $(TARGET)-$$TAG ]; then rm -rf $(TARGET)-$$TAG; fi
	@if [ -f $(TARGET)_$${TAG}.orig.tar.gz ]; then rm $(TARGET)_$${TAG}.orig.tar.gz; fi
	@mkdir $(TARGET)-$$TAG

_post_tarball:
	@pushd . && cd $(TARGET)-$(TAG) && find . \( -iname ".git*" -o -iname "*.bzr" -o -iname "*.hg" \) | xargs rm -rf \{} && \
	popd && tar zcvf $(TARGET)_$${TAG}.orig.tar.gz $(TARGET)-$$TAG
	@rm -rf $(TARGET)-$$TAG

_build:
	if [ -f debian/changelog.bkp ]; then rm debian/changelog.bkp; fi
	sed -i.bkp -e 's/\($(subst $(space),$(pipe),$(VERSIONS))\)/$(VERSION)/g' debian/changelog
	debuild --no-tgz-check -S -sa -us -uc
	mv debian/changelog.bkp debian/changelog

_do:
	for version in $(VERSIONS); do make VERSION=$$version CMD=$(TARGET) -C $(TARGET)-deb -f ../Makefile _build; done

_pre_check_launchpad:
	@if [ ! $$PPA ]; then \
		exit 0 ; \
	else \
		wget https://launchpad.net/~$$(echo $$PPA |cut -d'/' -f1)/+archive/$$(echo $$PPA |cut -d'/' -f2)/+files/$(TARGET)_$(TAG).orig.tar.gz ;  \
		content_tar_ball=$$(tar -tzf $(TARGET)_$(TAG).orig.tar.gz >/dev/null ; echo $$?) ; \
		if [ "$$content_tar_ball" == "0" ]; then \
			touch $(TARGET)_ppa_ok; \
			rm -rf $(TARGET)-$$TAG; \
		fi; \
	fi

tsuru-server: 
	make TAG=$$TAG TARGET=$@ _pre_tarball
	make TAG=$$TAG TARGET=$@ PPA=$$PPA _pre_check_launchpad
	$(eval PPA_SRC_OK := $(shell [[ -f $(TARGET)_ppa_ok ]]; echo $$?))
	@if [ "$(PPA_SRC_OK)" == "1" ] ; then pushd . && cd tsuru-server-$$TAG && pushd . && \
	export GOPATH=$$PWD && go get -v -u -d github.com/tsuru/tsuru/... && \
	export GOPATH=$$PWD && cd src/github.com/tsuru/tsuru && git checkout $$TAG && godep restore ./... && \
	rm -rf src/github.com/tsuru/tsuru/src && popd && make TAG=$$TAG TARGET=$@ PPA=$$PPA _post_tarball ; fi
	make TARGET=$@ _do


tsuru-node-agent:
	make TAG=$$TAG TARGET=$@ PPA=$$PPA _pre_check_launchpad
	make TAG=$$TAG TARGET=$@ PPA=$$PPA _pre_tarball
	$(eval PPA_SRC_OK := $(shell [[ -f $(TARGET)_ppa_ok ]]; echo $$?))
	@if [ "$(PPA_SRC_OK)" == "1" ] ; then pushd . && cd tsuru-node-agent-$$TAG && pushd . && \
	export GOPATH=$$PWD && go get -v -u -d github.com/tsuru/tsuru-node-agent/... && \
	export GOPATH=$$PWD && cd src/github.com/tsuru/tsuru-node-agent && git checkout $$TAG && godep restore ./... && \
	rm -rf src/github.com/tsuru/tsuru-node-agent/src && popd && make TAG=$$TAG TARGET=$@ _post_tarball ; fi
	make TARGET=$@ _do

serf:
	make TAG=$$TAG TARGET=$@ PPA=$$PPA _pre_check_launchpad
	make TAG=$$TAG TARGET=$@ PPA=$$PPA _pre_tarball
	$(eval PPA_SRC_OK := $(shell [[ -f $(TARGET)_ppa_ok ]]; echo $$?))
	@if [ "$(PPA_SRC_OK)" == "1" ] ; then pushd . && cd serf-$$TAG && pushd . && \
	export GOPATH=$$PWD && go get -v -u -d github.com/hashicorp/serf/... && \
	export GOPATH=$$PWD && cd src/github.com/hashicorp/serf && git checkout v$$TAG && popd && \
	make TAG=$$TAG TARGET=$@ _post_tarball ; fi
	make TARGET=$@ _do

gandalf-server:
	make TAG=$$TAG TARGET=$@ PPA=$$PPA _pre_check_launchpad
	make TAG=$$TAG TARGET=$@ PPA=$$PPA _pre_tarball
	$(eval PPA_SRC_OK := $(shell [[ -f $(TARGET)_ppa_ok ]]; echo $$?))
	@if [ "$(PPA_SRC_OK)" == "1" ] ; then pushd . && cd gandalf-server-$$TAG && pushd . && \
	export GOPATH=$$PWD && go get -v -u -d github.com/globocom/gandalf/... && cd src/github.com/globocom/gandalf && \
	git checkout $$TAG && godep restore ./... && popd && make TAG=$$TAG TARGET=$@ _post_tarball ; fi
	make TARGET=$@ _do

hipache-hchecker:
	make TAG=$$TAG TARGET=$@ PPA=$$PPA _pre_check_launchpad
	make TAG=$$TAG TARGET=$@ PPA=$$PPA _pre_tarball
	$(eval PPA_SRC_OK := $(shell [[ -f $(TARGET)_ppa_ok ]]; echo $$?))
	@if [ "$(PPA_SRC_OK)" == "1" ] ; then pushd . && cd hipache-hchecker-$$TAG && pushd . && \
	export GOPATH=$$PWD && go get -v -u -d github.com/morpheu/hipache-hchecker/... && cd src/github.com/morpheu/hipache-hchecker && \
	git checkout $$TAG && godep restore ./... && popd && make TAG=$$TAG TARGET=$@ _post_tarball ; fi
	make TARGET=$@ _do

nodejs:
	make TARGET=$@ _do

node-hipache:
	make TARGET=$@ _do

docker-registry:
	make TAG=$$TAG TARGET=$@ PPA=$$PPA _pre_check_launchpad
	make TAG=$$TAG TARGET=$@ _pre_tarball
	$(eval PPA_SRC_OK := $(shell [[ -f $(TARGET)_ppa_ok ]]; echo $$?))
	@if [ "$(PPA_SRC_OK)" == "1" ] ; then pushd . && cd docker-registry-$$TAG && pushd . && \
	export GOPATH=$$PWD && go get -v -u -d github.com/fsouza/docker-registry/contrib/golang_impl && cd src/github.com/fsouza/docker-registry/contrib/golang_impl && git checkout $$TAG && popd && make TAG=$$TAG TARGET=$@ _post_tarball ; fi
	make TARGET=$@ _do

tsuru-mongoapi:
	cd tsuru-mongoapi-deb && GOPATH=$$PWD go get -d github.com/globocom/mongoapi
	make TARGET=$@ _do

lxc-docker:
	if [ ! $$TAG ]; then echo "TAG env var must be set... use: TAG=<value> make $(TARGET)"; exit 1; fi
	if [ -d lxc-docker-$$TAG ]; then rm -rf lxc-docker-$$TAG; fi 
	if [ -d docker-$$TAG ]; then rm -rf docker-$$TAG; fi
	make TAG=$$TAG TARGET=$@ PPA=$$PPA _pre_check_launchpad
	$(eval PPA_SRC_OK := $(shell [[ -f $(TARGET)_ppa_ok ]]; echo $$?))
	@if [ "$(PPA_SRC_OK)" == "1" ] ; then curl -L -o lxc-docker-$$TAG.orig.tar.gz https://github.com/dotcloud/docker/archive/v$$TAG.tar.gz && \
	tar zxvf lxc-docker-$$TAG.orig.tar.gz && rm lxc-docker-$$TAG.orig.tar.gz && \
	mv docker-$$TAG lxc-docker-$$TAG && \
	pushd . && cd lxc-docker-$$TAG && GOPATH=$$PWD go get -d -v -u github.com/dotcloud/docker/docker... && popd && \
	pushd . && cd lxc-docker-$$TAG/src/github.com/dotcloud/docker && git fetch --tags && git checkout v$$TAG && popd && \
	pushd . && cd lxc-docker-$$TAG && find . \( -iname ".git*" -o -iname "*.bzr" -o -iname "*.hg" \) | xargs rm -rf \{} && popd && \
	tar zcvf lxc-docker_$$TAG.orig.tar.gz lxc-docker-$$TAG && rm -rf lxc-docker-$$TAG ; fi
	make TARGET=$@ _do

lvm2:
	if [ ! $$TAG ]; then echo "TAG env var must be set... use: TAG=<value> make $(TARGET)"; exit 1; fi
	if [ -f lvm2_$${TAG//_/.}.orig.tar.gz ]; then rm lvm2_$${TAG//_/.}.orig.tar.gz; fi
	make TAG=$$TAG TARGET=$@ PPA=$$PPA _pre_check_launchpad
	$(eval PPA_SRC_OK := $(shell [[ -f $(TARGET)_ppa_ok ]]; echo $$?))
	@if [ "$(PPA_SRC_OK)" == "1" ] ; then curl -L -o lvm2_$${TAG//_/.}.orig.tar.gz https://git.fedorahosted.org/cgit/lvm2.git/snapshot/lvm2-$$TAG.tar.gz; fi
	make TARGET=$@ _do

golang:
	if [ -f golang_1.2.orig.tar.gz ]; then rm golang_1.2.orig.tar.gz; fi
	make TAG=$$TAG TARGET=$@ PPA=$$PPA _pre_check_launchpad
	curl -L -o golang_1.2.orig.tar.gz http://go.googlecode.com/files/go1.2.src.tar.gz
	make TARGET=$@ _do
