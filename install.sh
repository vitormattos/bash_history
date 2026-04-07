#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GIST_DIR="$SCRIPT_DIR/gist"
TARGET_HISTORY="$GIST_DIR/.bash_history"
LEGACY_HISTORY="$GIST_DIR/bash_history"
LOCAL_HISTORY="$HOME/.bash_history"
CRON_ENTRY="*/1 * * * * $SCRIPT_DIR/backup.sh > $SCRIPT_DIR/backup.log 2>&1"

if [ ! -d "$GIST_DIR/.git" ]; then
    echo "Clone your secret gist into $GIST_DIR before running install.sh" >&2
    exit 1
fi

if [ -f "$LEGACY_HISTORY" ] && [ ! -f "$TARGET_HISTORY" ]; then
    mv "$LEGACY_HISTORY" "$TARGET_HISTORY"
fi

touch "$TARGET_HISTORY"

if [ ! -L "$LOCAL_HISTORY" ]; then
    if [ -f "$LOCAL_HISTORY" ]; then
        cat "$LOCAL_HISTORY" >> "$TARGET_HISTORY"
    fi

    ln -sf "$TARGET_HISTORY" "$LOCAL_HISTORY"
    echo "symlink created"
else
    ls -l "$LOCAL_HISTORY"
    echo "Check if the previous row is a link to your .bash_history in gist folder"
fi

(
    crontab -l 2>/dev/null | grep -Fv "$SCRIPT_DIR/backup.sh" || true
    echo "$CRON_ENTRY"
) | crontab -
echo "Crontab created"
echo "Generating the first backup..."
"$SCRIPT_DIR/backup.sh"