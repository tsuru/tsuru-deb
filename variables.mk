TMP = tmp
GOBASE := $(TMP)/gobase
GITBASE := $(TMP)/gitbase
NODEBASE := $(TMP)/nodebase

export VERSIONS := $(or $(VERSIONS),precise trusty wheezy)

DEBIAN_MIRROR = http://http.debian.net/debian
UBUNTU_MIRROR = http://archive.ubuntu.com/ubuntu

BUILDSUFFIX_precise = ~precise
BUILDTEXT_precise = "Backport to precise."
BUILDSUFFIX_saucy = ~saucy
BUILDTEXT_saucy = "Backport to saucy."
BUILDSUFFIX_trusty = ~trusty
BUILDTEXT_trusty = "Build for trusty."
BUILDSUFFIX_wheezy = ~bpo70+
BUILDTEXT_wheezy = "Rebuild for wheezy-backports."
BUILDDIST_wheezy = wheezy-backports
export DAILY_TAG := $(or $(DAILY_TAG),$(shell date +'SNAPSHOT%Y%m%d%H%M%S%z'))
export DAILY_BUILD := $(DAILY_BUILD)
DAILY_BUILD_EXCEPT = dh-golang golang nodejs node-hipache

export CHECK_LAUNCHPAD_FAIL := "no_error"

TAG_tsuru-server = 0.10.0
TAG_serf = 0.4.1
TAG_gandalf-server = 0.6.0
TAG_archive-server = 0.1.1
TAG_crane = 0.6.3
TAG_tsuru-client = 0.14.1
TAG_tsuru-admin = 0.8.2
TAG_hipache-hchecker = 0.2.4.3
TAG_docker-registry = 0.1.1
TAG_tsuru-mongoapi = 0.2.0
TAG_dh-golang = 1.5
TAG_golang = 1.4.0
TAG_nodejs = 0.10.26.3
TAG_node-hipache = 0.2.5

-include variables.local.mk

export CHECK_LAUNCHPAD := $(PPA)
