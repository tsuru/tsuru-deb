-include variables.mk

MIRROR_precise := $(UBUNTU_MIRROR)
MIRROR_saucy := $(UBUNTU_MIRROR)
MIRROR_trusty := $(UBUNTU_MIRROR)
MIRROR_wheezy := $(DEBIAN_MIRROR)
OTHERMIRROR_wheezy := deb $(MIRROR_wheezy) wheezy-backports main
EXTRAPACKAGES_wheezy := debian-backports-keyring
