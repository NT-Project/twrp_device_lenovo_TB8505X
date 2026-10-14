#!/sbin/sh

LOG=/tmp/auto_decrypt.log

log()
{
    echo "[TB8505X-DECRYPT] $*" >> "$LOG"
}

prop()
{
    getprop "$1" 2>/dev/null
}

wait_prop()
{
    NAME="$1"
    WANT="$2"
    MAX="${3:-50}"

    N=0
    while [ "$N" -lt "$MAX" ]; do
        VALUE="$(getprop "$NAME" 2>/dev/null)"
        [ "$VALUE" = "$WANT" ] && return 0
        sleep 0.1
        N=$((N + 1))
    done

    return 1
}

wait_process()
{
    NAME="$1"
    MAX="${2:-50}"

    N=0
    while [ "$N" -lt "$MAX" ]; do
        pidof "$NAME" >/dev/null 2>&1 && return 0
        sleep 0.1
        N=$((N + 1))
    done

    return 1
}

log "========================================"
log "TB-8505X automatic FDE bootstrap start"
log "========================================"

# Never inherit a stale READY state from an earlier attempt.
setprop tw.tb8505x.crypto.services.ready 0

#
# 1. Ensure vendor is available
#
mkdir -p /vendor

if [ ! -x /vendor/bin/teei_daemon ]; then
    log "Mounting vendor..."
    mount -t ext4 -o ro \
        /dev/block/platform/bootdevice/by-name/vendor \
        /vendor >>"$LOG" 2>&1
fi

if [ ! -x /vendor/bin/teei_daemon ]; then
    log "ERROR: /vendor/bin/teei_daemon unavailable"
    exit 10
fi

#
# 2. Mount stock system at /system_root
#
mkdir -p /system_root

if ! grep -q " /system_root " /proc/mounts; then
    log "Mounting system -> /system_root..."

    mount -t ext4 -o ro \
        /dev/block/platform/bootdevice/by-name/system \
        /system_root >>"$LOG" 2>&1
fi

if [ ! -x /system_root/system/bin/vold ]; then
    log "ERROR: stock vold unavailable"
    exit 11
fi

#
# 3. vdc_pie interpreter fix
#
if [ ! -e /sbin/linker64 ]; then
    log "Creating /sbin/linker64..."
    ln -s /system/bin/linker64 /sbin/linker64
fi

#
# 4. Expose STOCK framework VINTF to stock hwservicemanager
#
mkdir -p /system/etc/vintf

if ! grep -q " /system/etc/vintf " /proc/mounts; then
    log "Binding stock VINTF manifest..."

    mount --bind \
        /system_root/system/etc/vintf \
        /system/etc/vintf >>"$LOG" 2>&1
fi

if [ ! -f /system/etc/vintf/manifest.xml ]; then
    log "ERROR: stock framework VINTF manifest unavailable"
    exit 12
fi

#
# 5. Mount persist for Microtrust/RPMB state
#
mkdir -p /persist

if ! grep -q " /persist " /proc/mounts; then
    log "Mounting persist..."

    mount -t ext4 \
        /dev/block/platform/bootdevice/by-name/persist \
        /persist >>"$LOG" 2>&1
fi

mkdir -p /persist/rpmb
chmod 0771 /persist /persist/rpmb 2>/dev/null
chown system:system /persist /persist/rpmb 2>/dev/null

#
# 6. Microtrust device permissions copied from stock init
#
chmod 0660 /dev/teei_client 2>/dev/null
chown system:system /dev/teei_client 2>/dev/null

chmod 0660 /dev/teei_config 2>/dev/null
chown system:system /dev/teei_config 2>/dev/null

chmod 0666 /dev/tee0 2>/dev/null
chown system:drmrpc /dev/tee0 2>/dev/null

chmod 0660 /dev/tz_vfs 2>/dev/null
chown system:system /dev/tz_vfs 2>/dev/null

chmod 0660 /dev/teei_fp 2>/dev/null
chown system:root /dev/teei_fp 2>/dev/null

chmod 0660 /dev/ut_keymaster 2>/dev/null
chown system:drmrpc /dev/ut_keymaster 2>/dev/null

chmod 0660 /dev/rpmb0 2>/dev/null
chown system:system /dev/rpmb0 2>/dev/null

chmod 0660 /dev/emmcrpmb0 2>/dev/null
chown system:system /dev/emmcrpmb0 2>/dev/null

chmod 0660 /dev/utr_tui 2>/dev/null
chown system:system /dev/utr_tui 2>/dev/null

log "TEE device permissions prepared"

#
# 7. Start Microtrust teei_daemon
#
TEE_STATE="$(getprop init.svc.recovery_teei_daemon 2>/dev/null)"

if [ "$TEE_STATE" != "running" ]; then
    log "Starting Microtrust teei_daemon..."
    setprop ctl.start recovery_teei_daemon
fi

if ! wait_process teei_daemon 80; then
    log "ERROR: teei_daemon failed to start"
    exit 20
fi

log "teei_daemon running"

#
# 8. Replace recovery hwservicemanager with STOCK Android 10 one
#
if [ "$(getprop init.svc.hwservicemanager)" = "running" ]; then
    log "Stopping recovery hwservicemanager..."
    setprop ctl.stop hwservicemanager
    sleep 0.5
fi

log "Starting stock hwservicemanager..."
setprop ctl.start recovery_stock_hwservicemanager

if ! wait_process hwservicemanager 80; then
    log "ERROR: stock hwservicemanager failed to start"
    exit 21
fi

sleep 0.5

log "stock hwservicemanager running"

#
# 9. Start Microtrust CAPI using stock HIDL runtime
#
setprop ctl.stop teei_capi_2_0 2>/dev/null

if pidof vendor.microtrust.hardware.capi@2.0-service >/dev/null 2>&1; then
    kill "$(pidof vendor.microtrust.hardware.capi@2.0-service)" 2>/dev/null
    sleep 0.2
fi

log "Starting Microtrust CAPI..."
setprop ctl.start recovery_teei_capi

if ! wait_process vendor.microtrust.hardware.capi@2.0-service 80; then
    log "ERROR: Microtrust CAPI process failed to start"
    exit 22
fi

if ! wait_prop vendor.soter.teei.capi ready 100; then
    log "ERROR: vendor.soter.teei.capi did not become ready"
    log "Current value: $(getprop vendor.soter.teei.capi)"
    exit 23
fi

log "Microtrust CAPI ready"


#
# 10. Hand crypto ownership to TWRP
#
# IMPORTANT:
# Do not start Gatekeeper/Beanpod here.
# Do not start stock vold here.
# Do not run vdc_pie here.
# Do not mount /data here.
#
# TWRP vold_decrypt() must first override the recovery OS version and
# security patch level to match the installed Android system, then it
# will start the TB-8505X crypto services and perform checkpw itself.
#

if [ ! -f /etc/recovery.fstab ]; then
    log "ERROR: /etc/recovery.fstab missing"
    exit 30
fi

if [ ! -x /sbin/vdc_pie ]; then
    log "ERROR: /sbin/vdc_pie missing"
    exit 31
fi

if [ ! -e /sbin/linker64 ]; then
    log "ERROR: /sbin/linker64 missing"
    exit 32
fi

log "Microtrust bootstrap ready; handing decryption to TWRP"
setprop tw.tb8505x.crypto.services.ready 1

log "========================================"
log "TB-8505X crypto bootstrap READY"
log "========================================"

exit 0
