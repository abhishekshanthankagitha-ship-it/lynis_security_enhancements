#!/bin/bash

# Advanced Login Banner Security Audit
########################################

TEST_NO="CUST-9001"

echo "========================================"
echo " Advanced Login Banner Security Audit"
echo "========================================"

BANNER_FILES="/etc/issue /etc/issue.net"
REQUIRED_KEYWORDS="authorized unauthorized monitor"

for FILE in $BANNER_FILES; do

    echo
    echo "Checking $FILE"

    if [ ! -f "$FILE" ]; then

        echo "[WARNING] Banner file missing: $FILE"
        continue

    fi

    if [ ! -s "$FILE" ]; then

        echo "[WARNING] Banner file is empty: $FILE"
        continue

    fi

    echo "[OK] Banner file exists and is not empty"

    MISSING=""

    for KEYWORD in $REQUIRED_KEYWORDS; do

        if ! grep -Eiq "$KEYWORD" "$FILE"; then
            MISSING="$MISSING $KEYWORD"
        fi

    done

    if [ -z "$MISSING" ]; then

        echo "[OK] Required warning keywords are present"

    else

        echo "[WARNING] Missing keywords:$MISSING"

    fi

    if grep -Eiq \
    'password[[:space:]]*[:=]|api[_ -]?key[[:space:]]*[:=]|secret[[:space:]]*[:=]' \
    "$FILE"; then

        echo "[WARNING] Potentially sensitive information detected"

    else

        echo "[OK] No obvious credential assignments detected"

    fi

done

echo
echo "========================================"
echo " Security Audit Completed"
echo "========================================"
