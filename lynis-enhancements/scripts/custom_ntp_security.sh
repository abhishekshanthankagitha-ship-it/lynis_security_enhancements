#!/bin/bash

# Advanced NTP Configuration Security Audit
################################################

echo "=========================================="
echo " Advanced NTP Configuration Security Audit"
echo "=========================================="

CONFIG="/etc/systemd/timesyncd.conf"
DROPIN_DIR="/etc/systemd/timesyncd.conf.d"

EXPLICIT_SERVERS=""
FALLBACK_SERVERS=""
RUNTIME_SERVERS=""
CONFIG_FOUND=0
WARNINGS=0

# Check main configuration file

if [ -f "$CONFIG" ]; then

    CONFIG_FOUND=1

    echo "[OK] Main NTP configuration file found"

    EXPLICIT_SERVERS=$(awk -F= '
    /^[[:space:]]*[#;]/ { next }
    /^[[:space:]]*\[/ { next }
    /^[[:space:]]*NTP[[:space:]]*=/ {
        sub(/^[^=]*=/, "")
        print
    }' "$CONFIG")

    FALLBACK_SERVERS=$(awk -F= '
    /^[[:space:]]*[#;]/ { next }
    /^[[:space:]]*\[/ { next }
    /^[[:space:]]*FallbackNTP[[:space:]]*=/ {
        sub(/^[^=]*=/, "")
        print
    }' "$CONFIG")

else

    echo "[WARNING] Main NTP configuration file missing"
    WARNINGS=$((WARNINGS + 1))

fi

# Inspect drop-in files

if [ -d "$DROPIN_DIR" ]; then

    for FILE in "$DROPIN_DIR"/*.conf; do

        [ -f "$FILE" ] || continue

        CONFIG_FOUND=1

        echo "[INFO] Inspecting $FILE"

        DROPIN_NTP=$(awk -F= '
        /^[[:space:]]*[#;]/ { next }
        /^[[:space:]]*\[/ { next }
        /^[[:space:]]*NTP[[:space:]]*=/ {
            sub(/^[^=]*=/, "")
            print
        }' "$FILE")

        DROPIN_FALLBACK=$(awk -F= '
        /^[[:space:]]*[#;]/ { next }
        /^[[:space:]]*\[/ { next }
        /^[[:space:]]*FallbackNTP[[:space:]]*=/ {
            sub(/^[^=]*=/, "")
            print
        }' "$FILE")

        EXPLICIT_SERVERS="$EXPLICIT_SERVERS $DROPIN_NTP"
        FALLBACK_SERVERS="$FALLBACK_SERVERS $DROPIN_FALLBACK"

    done

fi

if [ "$CONFIG_FOUND" -eq 0 ]; then

    echo "[WARNING] No NTP configuration files found"
    WARNINGS=$((WARNINGS + 1))

fi

# Check explicit NTP servers

EXPLICIT_COUNT=$(printf '%s\n' "$EXPLICIT_SERVERS" |
    awk '{ for (i=1; i<=NF; i++) count++ }
    END { print count+0 }')

if [ "$EXPLICIT_COUNT" -ge 2 ]; then

    echo "[OK] At least two explicit NTP server entries found"

elif [ "$EXPLICIT_COUNT" -eq 1 ]; then

    echo "[WARNING] Only one explicit NTP server entry found"
    WARNINGS=$((WARNINGS + 1))

else

    echo "[INFO] No explicit NTP servers configured"

fi

# Check fallback servers

FALLBACK_COUNT=$(printf '%s\n' "$FALLBACK_SERVERS" |
    awk '{ for (i=1; i<=NF; i++) count++ }
    END { print count+0 }')

if [ "$FALLBACK_COUNT" -ge 2 ]; then

    echo "[OK] At least two fallback NTP server entries found"

elif [ "$FALLBACK_COUNT" -eq 1 ]; then

    echo "[WARNING] Only one fallback NTP server entry found"
    WARNINGS=$((WARNINGS + 1))

else

    echo "[INFO] No explicit fallback NTP servers configured"

fi

# Check effective runtime configuration

if command -v timedatectl >/dev/null 2>&1; then

    RUNTIME_INFO=$(timedatectl show-timesync --all 2>/dev/null)

    if [ -n "$RUNTIME_INFO" ]; then

        RUNTIME_SERVERS=$(printf '%s\n' "$RUNTIME_INFO" |
            awk -F= '
            /^ServerName=/ { print $2 }
            /^FallbackNTPServers=/ { print $2 }
            /^SystemNTPServers=/ { print $2 }
            /^RuntimeNTPServers=/ { print $2 }
            /^LinkNTPServers=/ { print $2 }')

        ACTIVE_SERVER=$(printf '%s\n' "$RUNTIME_INFO" |
            awk -F= '$1 == "ServerName" { print $2; exit }')

        echo "[INFO] Effective runtime NTP information retrieved"

        if [ -n "$ACTIVE_SERVER" ]; then

            echo "[OK] Active NTP server identified: $ACTIVE_SERVER"

        else

            echo "[INFO] No active NTP server name reported"

        fi

    else

        echo "[INFO] Runtime NTP configuration unavailable"

    fi

fi

# Check recognized server hostnames

ALL_SERVERS="$EXPLICIT_SERVERS $FALLBACK_SERVERS $RUNTIME_SERVERS"

TRUSTED_FOUND=0

for SERVER in $ALL_SERVERS; do

    case "$SERVER" in

        pool.ntp.org|*.pool.ntp.org|time.google.com|time.cloudflare.com)

            TRUSTED_FOUND=1
            ;;

    esac

done

if [ "$TRUSTED_FOUND" -eq 1 ]; then

    echo "[OK] Recognized time-service hostname found"

else

    echo "[INFO] No hostname from the example allowlist was identified"
    echo "[INFO] Verify time sources against your organization's policy"

fi

# Check systemd-timesyncd

if command -v systemctl >/dev/null 2>&1; then

    if systemctl is-active --quiet systemd-timesyncd; then

        echo "[OK] systemd-timesyncd service is active"

    else

        echo "[WARNING] systemd-timesyncd is not active"
        echo "[INFO] Check whether another approved NTP service is running"

    fi

fi

# Check clock synchronization

SYNC=$(timedatectl show -p NTPSynchronized --value 2>/dev/null)

if [ "$SYNC" = "yes" ]; then

    echo "[OK] System clock is synchronized"

else

    echo "[WARNING] System clock synchronization not confirmed"
    WARNINGS=$((WARNINGS + 1))

fi

# Final report

echo
echo "=========================================="
echo " NTP Security Audit Summary"
echo "=========================================="

echo "Explicit NTP entries: $EXPLICIT_COUNT"
echo "Explicit fallback entries: $FALLBACK_COUNT"
echo "Warnings requiring review: $WARNINGS"

echo "=========================================="
echo " NTP Security Audit Completed"
echo "=========================================="
