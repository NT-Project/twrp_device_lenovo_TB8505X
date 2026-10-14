#
# Copyright (C) 2021 The Android Open Source Project
# Copyright (C) 2021 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)

# Inherit from our custom product configuration
$(call inherit-product, vendor/omni/config/common.mk)

# Device identifier. This must come after all inclusions
PRODUCT_DEVICE := TB8505X
PRODUCT_NAME := omni_TB8505X
PRODUCT_BRAND := Lenovo
PRODUCT_MODEL := Lenovo TB-8505X
PRODUCT_MANUFACTURER := LENOVO

PRODUCT_SHIPPING_API_LEVEL := 28

# Crypto / FDE packages
PRODUCT_PACKAGES += \
    libkeymaster4 \
    libkeymaster4support \
    libkeymaster_messages \
    libkeymaster_portable \
    libpuresoftkeymasterdevice \
    libsoftgatekeeper \
    android.hardware.keymaster@4.0 \
    android.hardware.keymaster@3.0 \
    android.hardware.gatekeeper@1.0 \
    libkeystore-engine-wifi-hidl \
    libkeystore-wifi-hidl \
    libkmsetkey \
    keystore \
    gatekeeperd

PRODUCT_PACKAGES += \
    vendor.mediatek.hardware.keymaster_attestation@1.0 \
    vendor.mediatek.hardware.keymaster_attestation@1.1

PRODUCT_PACKAGES += \
    vold \
    secdiscard \
    vdc_pie \
    init.recovery.vold_decrypt.rc

# TB-8505X recovery crypto bootstrap
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/recovery/root/sbin/auto_decrypt.sh:$(TARGET_RECOVERY_ROOT_OUT)/sbin/auto_decrypt.sh \
    $(DEVICE_PATH)/recovery/root/init.recovery.crypto.rc:$(TARGET_RECOVERY_ROOT_OUT)/init.recovery.crypto.rc
