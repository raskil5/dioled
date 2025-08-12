include $(TOPDIR)/rules.mk

PKG_NAME:=dioled
PKG_VERSION:=1.3
PKG_RELEASE:=1

PKG_MAINTAINER:=raskil5
PKG_LICENSE:=GPL-2.0

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/dioled
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=LED signal and modem status indicator
  DEPENDS:=+lua +sms-tool  # Changed from comgt to sms-tool
endef

define Package/dioled/description
  A package to control modem and signal LEDs using sms-tool and Lua scripts.
endef

define Build/Prepare
	@mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Compile
	# No compile needed, only scripts
	true
endef

define Package/dioled/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/usr/bin/led_signal.lua $(1)/usr/bin/led_signal.lua

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/dioled $(1)/etc/init.d/dioled
	
	# Removed gcom directory and files since we're using sms-tool now
endef

define Package/dioled/postinst
#!/bin/sh
	chmod +x /etc/init.d/dioled
	chmod +x /usr/bin/led_signal.lua
	/etc/init.d/dioled enable
	/etc/init.d/dioled start
	exit 0
endef

$(eval $(call BuildPackage,dioled))
