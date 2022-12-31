################################################################################
#
# bl808-low-load
#
################################################################################

BL808_LOW_LOAD_SITE = $(BL808_LOW_LOAD_PKGDIR)/src
BL808_LOW_LOAD_SITE_METHOD = local
BL808_LOW_LOAD_INSTALL_IMAGES = YES
BL808_LOW_LOAD_INSTALL_TARGET = NO

define BL808_LOW_LOAD_INSTALL_IMAGES_CMDS
    cp $(@D)/low_load_bl808_d0.bin $(BINARIES_DIR)/low_load_bl808_d0.bin
    cp $(@D)/low_load_bl808_m0.bin $(BINARIES_DIR)/low_load_bl808_m0.bin
endef

$(eval $(generic-package))
