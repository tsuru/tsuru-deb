export TARGET := $(shell echo $@ | sed -r "s/(.+)(_[0-9\._-]+(-rc[0-9]+)?(\+1SNAPSHOT.+|~dfsg\d*)?\.orig\.tar\.(gz|bz2|xz)|\.build(src|deb)|\.upload)/\1/g")
export TAG := $(TAG_$(TARGET))

export SRCRESULT := $(CURDIR)/$(TARGET).buildsrc
export DEBRESULT := $(CURDIR)/$(TARGET).builddeb
export EXCEPT :=

GITTAG :=
GITPATH :=
TAR_OPTIONS :=
GOURL :=
URL :=

ifeq ($(TARGET),archive-server)
	GITPATH = github.com/tsuru/archive-server
	GOURL := $(GITPATH)
endif

ifeq ($(TARGET),crane)
	GITPATH = github.com/tsuru/crane
	export EXTRA_VERSIONS = $(EXTRA_VERSIONS_RELEASES)
	GOURL := $(GITPATH)
endif

ifeq ($(TARGET),deploy-agent)
	GITPATH = github.com/tsuru/deploy-agent
	GOURL := $(GITPATH)
endif

ifeq ($(TARGET),dh-golang)
	export EXCEPT = sid jessie saucy trusty utopic
	URL := https://launchpad.net/debian/+archive/primary/+files/dh-golang_$(TAG).tar.gz
endif

ifeq ($(TARGET),docker-registry)
	GITPATH = github.com/fsouza/docker-registry/contrib/golang_impl
	GOURL := $(GITPATH)
endif

ifeq ($(TARGET),gandalf-server)
	GITPATH = github.com/tsuru/gandalf
	GOURL := $(GITPATH)/...
endif

ifeq ($(TARGET),golang)
	export EXCEPT = sid jessie
	export EXTRA_VERSIONS = $(EXTRA_VERSIONS_RELEASES)
	URL := https://github.com/golang/go/archive/go$(TAG:.0=).tar.gz
endif

ifeq ($(TARGET),hipache-hchecker)
	GITPATH = github.com/morpheu/hipache-hchecker
	GOURL := $(GITPATH)/...
endif

ifeq ($(TARGET),nodejs)
	#URL := http://nodejs.org/dist/v$(TAG)/node-v$(TAG).tar.gz
	export EXCEPT = sid jessie
	URL := https://launchpad.net/~tsuru/+archive/ubuntu/ppa/+files/nodejs_$(TAG).orig.tar.gz
endif

ifeq ($(TARGET),serf)
	GITTAG := v$(TAG)
	GITPATH = github.com/hashicorp/serf
	GOURL := $(GITPATH)/...
endif

ifeq ($(TARGET),consul)
	GITTAG := v$(TAG)
	GITPATH = github.com/hashicorp/consul
	GOURL := $(GITPATH)/...
endif

ifeq ($(TARGET),consul-template)
	GITTAG := v$(TAG)
	GITPATH = github.com/hashicorp/consul-template
	GOURL := $(GITPATH)/...
endif

ifeq ($(TARGET),tsuru-admin)
	GITPATH = github.com/tsuru/tsuru-admin
	export EXTRA_VERSIONS = $(EXTRA_VERSIONS_RELEASES)
	GOURL := $(GITPATH)
endif

ifeq ($(TARGET),tsuru-client)
	GITPATH = github.com/tsuru/tsuru-client
	export EXTRA_VERSIONS = $(EXTRA_VERSIONS_RELEASES)
	GOURL := $(GITPATH)/...
endif

ifeq ($(TARGET),tsuru-mongoapi)
	GITPATH = github.com/tsuru/mongoapi
	GOURL := $(GITPATH)
endif

ifeq ($(TARGET),tsuru-server)
	GITPATH = github.com/tsuru/tsuru
	GOURL := $(GITPATH)/...
	TAR_OPTIONS := --exclude $(TARGET)-$(TAG)/src/$(GITPATH)/src
endif

ifneq (,$(findstring .upload,$@))
	export EXCEPT := $(EXCEPT) sid jessie wheezy
endif
