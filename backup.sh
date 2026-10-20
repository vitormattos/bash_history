#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BASEDIR="$SCRIPT_DIR/gist"
HISTORY_FILE="$BASEDIR/.bash_history"
LOCK_FILE="$BASEDIR/.git/bash-history-backup.lock"

[ -d "$BASEDIR/.git" ] || { echo 'Missing Gist repository' >&2; exit 1; }
[ -f "$HISTORY_FILE" ] || { echo 'Missing history file' >&2; exit 1; }
command -v flock >/dev/null 2>&1 || { echo 'flock required' >&2; exit 1; }
exec 9>"$LOCK_FILE"
flock -n 9 || { echo 'Backup already running'; exit 0; }

# Never trust a broken HEAD or overwrite history from a previous backup.
if git -C "$BASEDIR" cat-file -e HEAD:.bash_history 2>/dev/null; then
    PREVIOUS_PATH=.bash_history
elif git -C "$BASEDIR" cat-file -e HEAD:bash_history 2>/dev/null; then
    PREVIOUS_PATH=bash_history
else
    echo 'Missing or corrupt HEAD history' >&2
    exit 1
fi
PREVIOUS_LINES=$(git -C "$BASEDIR" show "HEAD:$PREVIOUS_PATH" | wc -l | tr -d ' ')
CURRENT_LINES=$(wc -l < "$HISTORY_FILE" | tr -d ' ')
if [ "$PREVIOUS_LINES" -gt 1000 ] && [ "$CURRENT_LINES" -lt "$PREVIOUS_LINES" ]; then
    echo "Refusing history shrink ($CURRENT_LINES < $PREVIOUS_LINES)" >&2
    exit 1
fi
# A valid backup must extend the previous history, not replace its contents.
PREVIOUS_BYTES=$(git -C "$BASEDIR" cat-file -s "HEAD:$PREVIOUS_PATH")
if ! git -C "$BASEDIR" show "HEAD:$PREVIOUS_PATH" | cmp -n "$PREVIOUS_BYTES" - "$HISTORY_FILE" >/dev/null 2>&1; then
    echo 'Refusing history rewrite: previous commands are missing or reordered' >&2
    exit 1
fi

# Fail closed if remote history advanced or is larger than the local snapshot.
BRANCH=$(git -C "$BASEDIR" symbolic-ref --quiet --short HEAD) || exit 1
REMOTE_HEAD=$(git -C "$BASEDIR" ls-remote origin "refs/heads/$BRANCH" | cut -f1)
[ -n "$REMOTE_HEAD" ] || { echo 'Cannot verify remote history' >&2; exit 1; }
LOCAL_HEAD=$(git -C "$BASEDIR" rev-parse HEAD)
[ "$REMOTE_HEAD" = "$LOCAL_HEAD" ] || { echo 'Remote changed: reconcile before backup' >&2; exit 1; }

if [ -z "$(git -C "$BASEDIR" status --porcelain -- .bash_history)" ]; then
    echo 'no changes'
    exit 0
fi

git -C "$BASEDIR" add -- .bash_history
git -C "$BASEDIR" -c commit.gpgSign=false commit -m "New backup $(date +'%Y-%m-%d %H:%M:%S')"
git -C "$BASEDIR" push origin "$BRANCH"
