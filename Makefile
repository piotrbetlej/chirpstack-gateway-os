.PHONY: build clean init update devshell show-envs switch-env

export TARGET_BOARD := full_raspberrypi_bcm27xx_bcm2709

# Build the OpenWrt image.
# Note: execute this within the devshell:
# quilt push -a && cd openwrt && make oldconfig && make -j$(nproc)

# Initialize the OpenWrt environment.
init:
	rm -rf .pc/
	git submodule init
	git submodule update
	cp feeds.conf.default openwrt/feeds.conf
	cp -rf ./conf/$(TARGET_BOARD)/files openwrt/
	cp -rf ./conf/$(TARGET_BOARD)/patches conf/
	docker-compose run --rm chirpstack-gateway-os openwrt/scripts/feeds update -a
	docker-compose run --rm chirpstack-gateway-os openwrt/scripts/feeds install -a
	docker-compose run --rm chirpstack-gateway-os quilt init
	cp -rf ./conf/$(TARGET_BOARD)/.config openwrt/
	rm -rf openwrt/.config.old

# Update OpenWrt + package feeds.
update:
	git submodule update
	cp feeds.conf.default openwrt/feeds.conf.default
	cd openwrt && \
		./scripts/feeds update -a && \
		./scripts/feeds install -a

# Activate the devshell.
devshell:
	docker-compose run --rm chirpstack-gateway-os bash

# Switch configuration environment.,
# Note: execute this within the devshell.
switch-env:
	@echo "Rollback previously applied patches"
	-cd openwrt && quilt pop -a

	@echo "Switching configuration"
	rm -f conf/files conf/patches conf/.config
	ln -s ${ENV}/files conf/files
	ln -s ${ENV}/patches conf/patches
	ln -s ${ENV}/.config conf/.config

	@echo "Applying patches"
	cd openwrt && quilt push -a

# Clean the OpenWrt environment.
clean:
	rm -rf openwrt
