all:
	@exit 0

download:
	GOPATH=$$PWD go get -u -d github.com/globocom/tsuru/cmd/tsuru

deb: download
	debuild --no-tgz-check -uc -us -b

deb-src: download
	debuild --no-tgz-check -S -sa
