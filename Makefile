all:
	@exit 0

clean:
	git clean -dfX

download:
	GOPATH=$$PWD go get -u -d github.com/globocom/tsuru/cmd/tsuru

_build: download
	debuild --no-tgz-check -S -sa

%:
	make -C $@-deb -f ../Makefile _build
