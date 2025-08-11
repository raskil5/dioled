include $(TOPDIR)/rules.mk

PKG_NAME:=dioled
PKG_VERSION:=1.1
PKG_RELEASE:=1
PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk

define Package/dioled
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=LED Signal + Modem Status Daemon
  DEPENDS:=+lua +comgt
endef

define Package/dioled/description
Background daemon to control router LEDs based on modem signal strength
and connection status, updating every few seconds.
endef

define Build/Compile
	true
endef

define Package/dioled/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/usr/bin/led_signal.lua $(1)/usr/bin/led_signal.lua
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/dioled $(1)/etc/init.d/dioled
endef

$(eval $(call BuildPackage,dioled))
