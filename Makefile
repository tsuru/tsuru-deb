DEFINED_VERSION=precise
VERSIONS="precise quantal raring saucy"

all:
	@exit 0

clean:
	git clean -dfX

local_setup:
	sudo apt-add-repository -y ppa:juju/golang
	sudo apt-get install golang -y
	mkdir /tmp/gopath
	GOPATH=/tmp/gopath go get github.com/kr/godep
	sudo mv /tmp/gopath/bin/godep /usr/bin
	rm -rf /tmp/gopath

download:
	GOPATH=$$PWD go get -u -d github.com/globocom/tsuru/...
	GOPATH=$$PWD cd src/github.com/globocom/tsuru && godep restore ./...

_build:
	sed -i.bkp -e 's/$(DEFINED_VERSION)/$(VERSION)/g' debian/changelog
	debuild --no-tgz-check -S -sa
	mv debian/changelog.bkp debian/changelog

_do:
	for version in "$(VERSIONS)"; do make VERSION=$$version CMD=$(TARGET) -C $(TARGET)-deb -f ../Makefile _build; done
	for file in *.changes; do dput ppa:tsuru/ppa $$file; done
	make clean

gandalf-server:
	cd gandalf-server-deb && GOPATH=$$PWD go get -u -d github.com/globocom/gandalf/...
	make TARGET=$@ _do

nodejs:
	make TARGET=$@ _do

node-hipache:
	make TARGET=$@ _do

docker-registry:
	cd docker-registry-deb && GOPATH=$$PWD go get -d github.com/fsouza/docker-registry/contrib/golang_impl
	make TARGET=$@ _do

%:
	make -C $@-deb -f ../Makefile download
	make TARGET=$@ _do
