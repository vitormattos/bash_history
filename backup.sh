#!/bin/sh

set -eu

if ! command -v git >/dev/null 2>&1; then
    echo "Git is not installed" >&2
    exit 1
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BASEDIR="$SCRIPT_DIR/gist"
HISTORY_FILE="$BASEDIR/.bash_history"

if [ ! -d "$BASEDIR/.git" ]; then
    echo "Gist repository not found at $BASEDIR" >&2
    exit 1
fi

if [ ! -f "$HISTORY_FILE" ]; then
    echo "History file not found at $HISTORY_FILE" >&2
    exit 1
fi

if git -C "$BASEDIR" rev-parse --verify HEAD >/dev/null 2>&1 \
    && git -C "$BASEDIR" cat-file -e HEAD:.bash_history 2>/dev/null; then
    PREVIOUS_LINES=$(git -C "$BASEDIR" show HEAD:.bash_history | wc -l | tr -d ' ')
    CURRENT_LINES=$(wc -l < "$HISTORY_FILE" | tr -d ' ')

    if [ "$PREVIOUS_LINES" -gt 1000 ] && [ "$CURRENT_LINES" -lt $((PREVIOUS_LINES / 2)) ]; then
        echo "Refusing to back up a truncated .bash_history ($CURRENT_LINES lines; previous commit has $PREVIOUS_LINES)." >&2
        exit 1
    fi
fi

if [ -z "$(git -C "$BASEDIR" status --porcelain -- .bash_history)" ]; then
    echo "no changes"
    exit 0
fi

CURRENT_BRANCH=$(git -C "$BASEDIR" rev-parse --abbrev-ref HEAD)

git -C "$BASEDIR" add .bash_history
git -C "$BASEDIR" -c commit.gpgSign=false commit -m "New backup $(date +'%Y-%m-%d %H:%M:%S')"
git -C "$BASEDIR" push origin "$CURRENT_BRANCH"