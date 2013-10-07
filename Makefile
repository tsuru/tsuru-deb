DEFINED_VERSION=precise
VERSIONS="precise quantal raring saucy"

all:
	@exit 0

clean:
	git clean -dfX

download:
	GOPATH=$$PWD go get -u -d github.com/globocom/tsuru/cmd/...

_build: download
	sed -i.bkp -e 's/$(DEFINED_VERSION)/$(VERSION)/g' debian/changelog
	debuild --no-tgz-check -S -sa
	mv debian/changelog.bkp debian/changelog

%: clean
	for version in "$(VERSIONS)"; do make VERSION=$$version CMD=$@ -C $@-deb -f ../Makefile _build; done
