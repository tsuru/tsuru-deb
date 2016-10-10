TMP = tmp
GOBASE := $(TMP)/gobase
GITBASE := $(TMP)/gitbase
NODEBASE := $(TMP)/nodebase

export VERSIONS := $(or $(VERSIONS),precise trusty xenial wheezy)
export EXTRA_VERSIONS_RELEASES := $(or $(EXTRA_VERSIONS_RELEASES), wily)
export GO15VENDOREXPERMIENT := 1

DEBIAN_MIRROR = http://http.debian.net/debian
UBUNTU_MIRROR = http://archive.ubuntu.com/ubuntu

BUILDSUFFIX_precise = ~precise
BUILDTEXT_precise = "Backport to precise."
BUILDSUFFIX_trusty = ~trusty
BUILDTEXT_trusty = "Build for trusty."
BUILDSUFFIX_wily = ~wily
BUILDTEXT_wily= "Build for wily."
BUILDSUFFIX_xenial = ~xenial
BUILDTEXT_xenial= "Build for xenial."
BUILDSUFFIX_wheezy = ~bpo70+
BUILDTEXT_wheezy = "Rebuild for wheezy-backports."
BUILDDIST_wheezy = wheezy-backports
export DAILY_TAG := $(or $(DAILY_TAG),$(shell date +'SNAPSHOT%Y%m%d%H%M%S%z'))
export DAILY_BUILD := $(DAILY_BUILD)
DAILY_BUILD_EXCEPT = dh-golang golang

export CHECK_LAUNCHPAD_FAIL := "no_error"

TAG_tsuru-server = 1.1.0
TAG_serf = 0.4.1
TAG_consul = 0.6.4
TAG_consul-template = 0.14.0
TAG_gandalf-server = 0.7.3
TAG_archive-server = 0.2.1
TAG_crane = 1.0.0
TAG_tsuru-client = 1.1.1
TAG_tsuru-admin = 1.0.0
TAG_hipache-hchecker = 0.2.4.3
TAG_docker-registry = 0.1.1
TAG_tsuru-mongoapi = 0.2.0
TAG_dh-golang = 1.5
TAG_golang = 1.4.0
TAG_deploy-agent = 0.2.2
TAG_planb = 0.1.7

-include variables.local.mk

export CHECK_LAUNCHPAD := $(PPA)
