TMP = tmp
GOBASE := $(TMP)/gobase
GITBASE := $(TMP)/gitbase
NODEBASE := $(TMP)/nodebase

VERSIONS=precise trusty wheezy

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
DAILY_BUILD_EXCEPT = dh-golang lvm2 btrfs-tools golang nodejs node-hipache

TAG_tsuru-server = 0.6.2.1
TAG_serf = 0.4.1
TAG_gandalf-server = 0.5.0
TAG_archive-server = 0.1.1
TAG_crane = 0.5.4
TAG_tsuru-client = 0.11.2
TAG_tsuru-admin = 0.5.1
TAG_hipache-hchecker = 0.2.4.2
TAG_docker-registry = 0.1.1
TAG_tsuru-mongoapi = 0.2.0
TAG_lxc-docker = 1.1.1
TAG_dh-golang = 1.5
TAG_lvm2 = 2.02.103
TAG_btrfs-tools = 3.12
TAG_golang = 1.2.1
TAG_nodejs = 0.10.26.3
TAG_node-hipache = 0.2.5

-include variables.local.mk
