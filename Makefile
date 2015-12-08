.SECONDEXPANSION:
SHELL=/bin/bash

comma:= ,
empty:=
space:= $(empty) $(empty)
pipe:= \|
hyphen := -

GOVERSION := $(shell go version 2>/dev/null | sed 's/go version[^0-9]*\([0-9.]*\).*/\1/')
GOPATH := $(shell echo $$PWD)

include header.mk

all:
	@exit 0

clean:
	rm -rf $(CURDIR)/$(TMP)
	sudo git --git-dir=$(CURDIR)/.git clean -dfX --e \!variables.local.mk --e \!builder --e \!localrepo

prepare:
	sudo apt-get update
	sudo apt-get install software-properties-common -y
	sudo apt-add-repository ppa:tsuru/golang15 -y
	sudo apt-get update
	sudo apt-get install golang debhelper devscripts git mercurial ubuntu-dev-tools cowbuilder gnupg-agent -y
	@if [ ! -d /tmp/gopath ]; then mkdir /tmp/gopath; fi
	GOPATH=/tmp/gopath go get github.com/kr/godep
	@sudo mv /tmp/gopath/bin/godep /usr/bin
	@rm -rf /tmp/gopath

builddeb: $(patsubst %-deb,%.builddeb,$(wildcard *-deb))

buildsrc: $(patsubst %-deb,%.buildsrc,$(wildcard *-deb))

upload: $(patsubst %-deb,%.upload,$(wildcard *-deb))

# upload to PPA
# =============

$(strip $(VERSIONS:%=_upload.%) $(EXTRA_VERSIONS:%=_upload.%)):
	$(eval VERSION := $(@:_upload.%=%))
	$(eval buildsfx := $(BUILDSUFFIX_$(VERSION)))
	eval $$(gpg-agent --daemon) && debsign -k $(GPGID) $(SRCRESULT).tmp/*$(buildsfx)*.changes
	dput ppa:$(PPA) $(SRCRESULT).tmp/*$(buildsfx)*.changes

_upload: $(patsubst %,_upload.%,$(strip $(filter-out $(EXCEPT),$(VERSIONS)) $(EXTRA_VERSIONS)))

$(patsubst %-deb,%.upload,$(wildcard *-deb)): %.upload: %.buildsrc
	@if [ ! $(PPA) ]; then \
		echo "PPA var must be set to upload packages... use: PPA=<value> make upload"; \
		exit 1; \
	fi
	@if [ ! $(GPGID) ]; then \
		echo 'Specify your GPG id/email in `variables.local.mk`:' >&2; \
		echo 'GPGID = [GPG id|GPG email]' >&2; \
		echo >&2; \
		echo 'You can generate your own GPG key with gnupg:' >&2; \
		echo '$$ sudo apt-get install gnupg' >&2; \
		echo '$$ gpg --gen-key' >&2; \
		exit 1; \
	fi
	$(eval include scopedvars.mk)
	@rm -rf $(SRCRESULT).tmp 2>/dev/null || true
	cp -a $(SRCRESULT) $(SRCRESULT).tmp
	$(MAKE) PPA=$(PPA) _upload
	rm -rf $(SRCRESULT).tmp

# reprepro initialization
# =======================

$(strip $(VERSIONS:%=_distributions.%) $(EXTRA_VERSIONS:%=_distributions.%)):
	$(eval VERSION := $(@:_distributions.%=%))
	$(eval dist := $(CURDIR)/localrepo.tmp/conf/distributions)
	echo "Origin: tsuru-deb" >> $(dist)
	echo "Label: tsuru-deb" >> $(dist)
	echo "Codename: $(or $(BUILDDIST_$(VERSION)),$(VERSION))" >> $(dist)
	echo "Architectures: i386 amd64 source" >> $(dist)
	echo "Components: main contrib" >> $(dist)
	echo "UDebComponents: main contrib" >> $(dist)
	echo "Description: tsuru-deb local repository" >> $(dist)
	echo "SignWith: yes" >> $(dist)
	echo >> $(dist)

localrepo/conf:
	# Creating a local APT repository...
	# based on http://joseph.ruscio.org/blog/2010/08/19/setting-up-an-apt-repository/
	# thanks to Joseph Ruuscio
	$(eval localrepo := $(CURDIR)/localrepo)
	@if [ ! $(GPGID) ]; then \
		echo 'Specify your GPG id/email in `variables.local.mk`:' >&2; \
		echo 'GPGID = [GPG id|GPG email]' >&2; \
		echo >&2; \
		echo 'You can generate your own GPG key with gnupg:' >&2; \
		echo '$$ sudo apt-get install gnupg' >&2; \
		echo '$$ gpg --gen-key' >&2; \
		exit 1; \
	fi
	sudo apt-get update -qq
	sudo apt-get install reprepro gnupg -y
	rm -rf $(localrepo).tmp 2>/dev/null || true
	mkdir -p $(localrepo).tmp/conf
	$(MAKE) $(patsubst %,_distributions.%,$(strip $(filter-out $(EXCEPT),$(VERSIONS)) $(EXTRA_VERSIONS)))
	echo "verbose" >> $(localrepo).tmp/conf/options
	echo "ask-passphrase" >> $(localrepo).tmp/conf/options
	echo "basedir ." >> $(localrepo).tmp/conf/options
	gpg --armor --output $(localrepo).tmp/public.key --export $(GPGID)
	cd $(localrepo).tmp && reprepro export
	mv $(localrepo).tmp $(localrepo)

localrepo: localrepo/conf

# cowbuilder initialization
# =========================

$(strip $(VERSIONS:%=builder/%-base.cow) $(EXTRA_VERSIONS:%=builder/%-base.cow)):
	$(eval VERSION := $(@:builder/%-base.cow=%))
	$(eval export MIRRORSITE = $(MIRROR_$(VERSION)))
	$(eval export OTHERMIRROR = $(OTHERMIRROR_$(VERSION)))
	$(eval export EXTRAPACKAGES = $(EXTRAPACKAGES_$(VERSION)))
	$(eval export PBUILDFOLDER = $(CURDIR)/builder)
	$(eval builddist := $(or $(BUILDDIST_$(VERSION)),$(VERSION)))
	$(eval localrepo := $(CURDIR)/localrepo)
	sudo rm -rf $@ || true
	cowbuilder-dist $(VERSION) create --updates-only
	rm /tmp/repo.sh 2>/dev/null || true
	echo "apt-get update -qq" > /tmp/repo.sh
	echo "apt-get install apt-utils -y" >> /tmp/repo.sh
	echo "echo 'deb file://$(localrepo) $(builddist) main' > /etc/apt/sources.list.d/local_$(builddist).list" >> /tmp/repo.sh
	echo "echo 'deb-src file://$(localrepo) $(builddist) main' >> /etc/apt/sources.list.d/local_$(builddist).list" >> /tmp/repo.sh
	echo "cat $(localrepo)/public.key | apt-key add -" >> /tmp/repo.sh
	cowbuilder-dist $(VERSION) execute --bindmounts $(localrepo) --save --override-config --updates-only /tmp/repo.sh
	cowbuilder-dist $(VERSION) update --bindmounts $(localrepo) --override-config --updates-only
	rm /tmp/repo.sh 2>/dev/null || true
	@sudo touch $@

builder: localrepo/conf $(patsubst %,builder/%-base.cow,$(strip $(filter-out $(EXCEPT),$(VERSIONS)) $(EXTRA_VERSIONS)))
	@touch builder

# builddeb-related rules
# ======================

$(strip $(VERSIONS:%=_builddeb.%) $(EXTRA_VERSIONS:%=_builddeb.%)):
	$(eval VERSION := $(@:_builddeb.%=%))
	$(eval export MIRRORSITE = $(MIRROR_$(VERSION)))
	$(eval export OTHERMIRROR = $(OTHERMIRROR_$(VERSION)))
	$(eval export EXTRAPACKAGES = $(EXTRAPACKAGES_$(VERSION)))
	$(eval export PBUILDFOLDER = $(CURDIR)/builder.tmp)
	@sudo rm -rf $(PBUILDFOLDER) 2>/dev/null || true
	sudo cp -la $(CURDIR)/builder $(PBUILDFOLDER)
	cowbuilder-dist $(VERSION) update --bindmounts $(CURDIR)/localrepo --override-config --updates-only
	cowbuilder-dist $(VERSION) build $(SRCRESULT)/$(TARGET)_*$(BUILDSUFFIX_$(VERSION))*.dsc --buildresult=$(DEBRESULT).tmp/$(VERSION) --debbuildopts="-sa" --bindmounts=$(CURDIR)/localrepo
	sudo rm -rf $(PBUILDFOLDER)
	-cd $(CURDIR)/localrepo && ls $(DEBRESULT).tmp/$(VERSION)/*.changes | xargs --verbose -L 1 reprepro include $(or $(BUILDDIST_$(VERSION)),$(VERSION))

_builddeb: localrepo $(patsubst %,_builddeb.%,$(strip $(filter-out $(EXCEPT),$(VERSIONS)) $(EXTRA_VERSIONS)))

tsuru-server.builddeb serf.builddeb consul.builddeb consul-template.builddeb planb.builddeb gandalf-server.builddeb archive-server.builddeb crane.builddeb tsuru-client.builddeb tsuru-admin.builddeb hipache-hchecker.builddeb docker-registry.builddeb tsuru-mongoapi.builddeb deploy-agent.builddeb: golang.builddeb

$(patsubst %-deb,%.builddeb,$(wildcard *-deb)): %.builddeb: builder %.buildsrc
	$(eval include scopedvars.mk)
	sudo rm -rf $(DEBRESULT) $(DEBRESULT).tmp/* 2>/dev/null || true
	mkdir -p $(DEBRESULT).tmp
	$(MAKE) _builddeb
	sudo mv $(DEBRESULT).tmp $(DEBRESULT)
	touch $(DEBRESULT)

# original tarball rules
# ======================

dtag := $(and $(DAILY_BUILD),+1$(DAILY_TAG))

tsuru-server_$(TAG_tsuru-server)$(dtag).orig.tar.gz serf_$(TAG_serf)$(dtag).orig.tar.gz consul_$(TAG_consul)$(dtag).orig.tar.gz consul-template_$(TAG_consul-template)$(dtag).orig.tar.gz planb_$(TAG_planb)$(dtag).orig.tar.gz gandalf-server_$(TAG_gandalf-server)$(dtag).orig.tar.gz archive-server_$(TAG_archive-server)$(dtag).orig.tar.gz crane_$(TAG_crane)$(dtag).orig.tar.gz tsuru-client_$(TAG_tsuru-client)$(dtag).orig.tar.gz tsuru-admin_$(TAG_tsuru-admin)$(dtag).orig.tar.gz hipache-hchecker_$(TAG_hipache-hchecker)$(dtag).orig.tar.gz docker-registry_$(TAG_docker-registry)$(dtag).orig.tar.gz tsuru-mongoapi_$(TAG_tsuru-mongoapi)$(dtag).orig.tar.gz deploy-agent_$(TAG_deploy-agent)$(dtag).orig.tar.gz:
	$(eval include scopedvars.mk)
	$(eval export GOPATH = $(CURDIR)/$(GOBASE)/$(TARGET)-$(TAG))
ifeq ($(and $(CHECK_LAUNCHPAD), $(CHECK_LAUNCHPAD_FAIL)), "no_error")
	wget https://launchpad.net/~$$(echo $(PPA) | cut -d'/' -f1)/+archive/$$(echo $(PPA) | cut -d'/' -f2)/+files/$@ ;  \
	content_tar_ball=$$(tar -tzf $@ >/dev/null ; echo $$?) ; \
	if [ "$$content_tar_ball" != "0" ]; then \
		rm $@; \
		$(MAKE) CHECK_LAUNCHPAD="" CHECK_LAUNCHPAD_FAIL="yes" $@; \
	fi
else
	rm -rf $(GOPATH) 2>/dev/null || true
	mkdir -p $(GOPATH)
	go get -v -u -d $(or $(GOURL),$(GITPATH)/...)
	set -e; \
	if [ ! "$(DAILY_BUILD)" ]; then \
		git -C $(GOPATH)/src/$(GITPATH) checkout $(or $(GITTAG),$(TAG)); \
	fi
	set -e; \
	if [[ -d $(GOPATH)/src/$(GITPATH)/Godeps ]]; then \
		cd $(GOPATH)/src/$(GITPATH); \
		godep restore ./...; \
	fi
	tar -zcf $@ -C $(CURDIR)/$(GOBASE) $(TARGET)-$(TAG) --exclude-vcs $(TAR_OPTIONS)
endif

dh-golang_$(TAG_dh-golang).orig.tar.gz golang_$(TAG_golang).orig.tar.gz:
	$(eval include scopedvars.mk)
	curl -L -o $@ $(URL)

# buildsrc-related rules
# ======================

$(strip $(VERSIONS:%=_buildsrc.%) $(EXTRA_VERSIONS:%=_buildsrc.%)):
	$(eval VERSION := $(@:_buildsrc.%=%))
	$(eval debver := $(and $(filter-out $(DAILY_BUILD_EXCEPT),$(TARGET)),$(DAILY_BUILD),$(TAG)$(dtag)))
	cp $(SRCRESULT).tmp/$(TARGET)/debian/changelog /tmp/$(TARGET).changelog.orig
	set -e; \
	cd $(SRCRESULT).tmp/$(TARGET); \
	if [ $(debver) ]; then \
		dch -v $(debver)-1$(BUILDSUFFIX_$(VERSION))1 -D $(or $(BUILDDIST_$(VERSION)),$(VERSION)) $(BUILDTEXT_$(VERSION)); \
	else \
		dch -l $(BUILDSUFFIX_$(VERSION)) -D $(or $(BUILDDIST_$(VERSION)),$(VERSION)) $(BUILDTEXT_$(VERSION)); \
	fi
	cd $(SRCRESULT).tmp/$(TARGET); debuild --no-tgz-check -S -sa -us -uc
	mv /tmp/$(TARGET).changelog.orig $(SRCRESULT).tmp/$(TARGET)/debian/changelog

_buildsrc: $(patsubst %,_buildsrc.%,$(strip $(filter-out $(EXCEPT),$(VERSIONS)) $(EXTRA_VERSIONS)))

tsuru-server.buildsrc serf.buildsrc consul.buildsrc consul-template.buildsrc planb.buildsrc gandalf-server.buildsrc archive-server.buildsrc crane.buildsrc tsuru-client.buildsrc tsuru-admin.buildsrc hipache-hchecker.buildsrc docker-registry.buildsrc tsuru-mongoapi.buildsrc deploy-agent.buildsrc : $$(patsubst %.buildsrc,%,$$@)_$$(TAG_$$(patsubst %.buildsrc,%,$$@))$(dtag).orig.tar.gz
golang.buildsrc dh-golang.buildsrc: $$(patsubst %.buildsrc,%,$$@)_$$(TAG_$$(patsubst %.buildsrc,%,$$@)).orig.tar.gz
tsuru-server.buildsrc serf.buildsrc consul.buildsrc consul-template.buildsrc planb.buildsrc gandalf-server.buildsrc archive-server.buildsrc crane.buildsrc tsuru-client.buildsrc tsuru-admin.buildsrc hipache-hchecker.buildsrc docker-registry.buildsrc tsuru-mongoapi.buildsrc golang.buildsrc dh-golang.buildsrc deploy-agent.buildsrc: %.buildsrc: %-deb %-deb/debian
	$(eval include scopedvars.mk)
	rm -rf $(SRCRESULT) $(SRCRESULT).tmp/* || true
	mkdir -p $(SRCRESULT).tmp/$(TARGET)
	cp -r $(CURDIR)/$(TARGET)-deb/* $(SRCRESULT).tmp/$(TARGET)
	-cp $(CURDIR)/$(TARGET)_$(TAG)$(and $(filter-out $(DAILY_BUILD_EXCEPT),$(TARGET)),$(DAILY_BUILD),$(dtag)).orig.tar.{xz,gz,bz2} $(SRCRESULT).tmp 2>/dev/null
	$(MAKE) _buildsrc
	rm -rf $(SRCRESULT).tmp/$(TARGET) || true
	mv $(SRCRESULT).tmp $(SRCRESULT)
	touch $(SRCRESULT)
