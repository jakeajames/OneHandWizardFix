include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OneHandWizardFix
OneHandWizardFix_FILES = Tweak.xm
CFLAGS = -Wno-everything -fobjc-arc
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
