DEFINED_VERSION=precise
VERSIONS="precise quantal raring saucy"

all:
	@exit 0

clean:
	git clean -dfX

download:
	GOPATH=$$PWD go get -u -d github.com/globocom/tsuru/cmd/...

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
	cd docker-registry-deb && GOPATH=$$PWD go get -d github.com/dotcloud/docker-registry/contrib/golang_impl
	make TARGET=$@ _do

%:
	make -C $@-deb -f ../Makefile download
	make TARGET=$@ _do
