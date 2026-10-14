# TWRP Device Tree for Lenovo Tab M8 TB-8505X

Unofficial Team Win Recovery Project device tree for the **Lenovo Tab M8 TB-8505X**.

This tree was ported and brought up against the stock Android 10 firmware of the TB-8505X and includes device-specific fixes for encryption, System-As-Root handling, Vendor mount behavior, USB OTG, and TWRP source compatibility.

**Maintainer:** NK203 x Codex

---

## Device Information

| Item | Value |
|---|---|
| Device | Lenovo Tab M8 |
| Model | TB-8505X |
| Product | TB8505X / akita_row_call |
| Platform | MediaTek MT6761 / MT8766 family |
| Architecture | ARM64 |
| Android base | Android 10 |
| Kernel | 4.9.x |
| Partition scheme | Non-A/B |
| System layout | System-As-Root |
| Recovery partition | 32 MiB |
| Internal storage | `/data/media/0` |
| Data encryption | Supported |

---

## Current Status

### Working

- Recovery boot
- Touchscreen
- Display / TWRP UI
- Internal Storage
- `/data` decryption
- Encrypted userdata access
- PIN / password decryption
- System-As-Root handling
- System mount / unmount
- Vendor mount / unmount
- Data mount
- System read/write toggle
- Vendor read-only handling
- File Manager
- Terminal
- ADB
- MTP
- USB OTG
- Backup to Internal Storage
- Backup directly to USB OTG
- Restore
- Install ZIP
- Install Image
- Flash `recovery.img`
- Flash `boot.img`
- Flash Magisk-patched boot images
- Reboot to Android
- Reboot to Recovery
- Vietnamese localization
- Stock Android boots normally after recovery usage

### Not Fully Tested / Incomplete

- ADB Sideload
- Fastboot mode inside TWRP
- USB Mass Storage
- OTA installation
- Every possible backup / restore partition combination
- Custom ROM flashing
- Advanced FBE edge cases after Format Data
- Rescue Party related paths
- Some Vietnamese strings may still need UI refinement

---

## Device-Specific Notes

### Vendor must remain read-only

The stock TB-8505X Vendor partition does not behave correctly when TWRP tries to remount it read/write.

The final recovery therefore keeps Vendor read-only:

```text
/vendor -> ext4, ro
```

System may still be mounted read/write when requested.

Do not force Vendor read/write unless you know exactly what you are doing.

### Encryption

Android 10 userdata decryption required device-specific handling around:

- stock VINTF
- vold
- Gatekeeper
- Microtrust / Beanpod services
- metadata-backed encryption
- Android security patch properties
- crypto service lifecycle

The current build is able to decrypt `/data` and expose the real internal storage at:

```text
/data/media/0
```

### Vendor stale mount cleanup

After crypto services stop, the stock Vendor mount may remain busy.

A device-specific cleanup path is used to detach only the stale Vendor mount after the normal unmount path fails.

This workaround is intentionally limited to the TB-8505X crypto cleanup path.

---

## Repository Layout

```text
device/Lenovo/TB8505X/
├── Android.mk
├── AndroidProducts.mk
├── BoardConfig.mk
├── omni_TB8505X.mk
├── patches/
│   ├── apply.sh
│   ├── tb8505x-twrp-core.patch
│   ├── vdc_pie-arm64
│   └── vi.xml
├── prebuilt/
└── recovery/
    └── root/
```

The `patches/` directory contains the additional TWRP source changes required by this device.

---

## Applying TWRP Source Patches

From a synced TWRP Android 10 source tree:

```bash
bash device/Lenovo/TB8505X/patches/apply.sh
```

The script installs:

- final TB-8505X TWRP core patch
- Android 10 compatible `vdc_pie`
- Vietnamese localization
- required compatibility headers

The final core patch modifies TWRP components including:

```text
crypto/vold_decrypt/
etc/init.rc
gui/action.cpp
gui/theme/common/languages/en.xml
partitionmanager.cpp
prebuilt/Android.mk
twrp.cpp
```

---

## Build

Example build commands:

```bash
cd /mnt/android/twrp/source

source build/envsetup.sh
lunch omni_TB8505X-eng

export ALLOW_MISSING_DEPENDENCIES=true

mka recoveryimage -j4
```

The resulting recovery image should be located at:

```text
out/target/product/TB8505X/recovery.img
```

Check the image size and SHA256 before flashing:

```bash
stat -c '%n %s bytes' out/target/product/TB8505X/recovery.img
sha256sum out/target/product/TB8505X/recovery.img
```

The TB-8505X recovery partition size is:

```text
33554432 bytes
32 MiB
```

Do not flash an oversized recovery image.

---

## Flashing

Only flash recovery images built for the Lenovo TB-8505X.

Example:

```bash
fastboot flash recovery recovery.img
```

After flashing, boot directly into recovery if necessary to prevent the stock system from restoring stock recovery.

---

## Important Warnings

- Do not blindly flash images built for the TB-8505F or another Lenovo variant.
- Do not force Vendor read/write.
- Do not modify metadata or encryption-related partitions without a verified backup.
- Do not use recovery images from unrelated MT6761 / MT8766 devices.
- Keep a full stock firmware package available before testing recovery or ROM changes.

---

## Vietnamese Localization

Vietnamese language support is included.

Translation and contextual localization:

```text
NK203 x Codex
```

Technical Android / TWRP terms are intentionally kept in English where that is clearer than a literal Vietnamese translation.

---

## Credits

- Team Win Recovery Project
- OmniROM / TWRP Android 10 sources
- HemanthJabalpuri for the original TB-8505F tree used as the initial base
- Lenovo / MediaTek stock firmware components
- **NK203 x Codex** — TB-8505X bring-up, Android 10 decryption, Vendor mount fixes, source patches, testing and Vietnamese localization

---

## Project Status

The recovery is currently considered usable for day-to-day recovery tasks on the tested TB-8505X stock firmware.

Possible future work:

- additional recovery function testing
- OrangeFox bring-up
- AOSP / LineageOS bring-up
- custom ROM development for the TB-8505X
