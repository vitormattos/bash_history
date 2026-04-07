#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

setup_git_repo() {
    repo_dir=$1
    remote_dir=$2

    git init -q -b main "$repo_dir"
    git -C "$repo_dir" config user.name "Test User"
    git -C "$repo_dir" config user.email "test@example.com"
    git -C "$repo_dir" config commit.gpgsign false
    git init -q --bare "$remote_dir"
    git -C "$repo_dir" remote add origin "$remote_dir"
}

test_install_preserves_existing_history() {
    sandbox="$TMP_DIR/install"
    mkdir -p "$sandbox/home" "$sandbox/bin" "$sandbox/gist"
    cp "$ROOT_DIR/install.sh" "$ROOT_DIR/backup.sh" "$sandbox/"

    setup_git_repo "$sandbox/gist" "$sandbox/remote.git"

    printf 'date\n' > "$sandbox/gist/bash_history"
    git -C "$sandbox/gist" add bash_history
    git -C "$sandbox/gist" commit -qm "Initial gist"
    git -C "$sandbox/gist" push -q -u origin main

    {
        printf '%s\n' '#!/bin/sh'
        printf '%s\n' "store=\"$sandbox/crontab.txt\""
        printf '%s\n' 'if [ "${1:-}" = "-l" ]; then'
        printf '%s\n' '    if [ -f "$store" ]; then'
        printf '%s\n' '        cat "$store"'
        printf '%s\n' '    else'
        printf '%s\n' '        exit 1'
        printf '%s\n' '    fi'
        printf '%s\n' 'else'
        printf '%s\n' '    cat > "$store"'
        printf '%s\n' 'fi'
    } > "$sandbox/bin/crontab"
    chmod +x "$sandbox/bin/crontab"

    printf 'local-command\n' > "$sandbox/home/.bash_history"

    PATH="$sandbox/bin:$PATH" HOME="$sandbox/home" sh "$sandbox/install.sh" >/dev/null

    [ -L "$sandbox/home/.bash_history" ] || fail "install.sh did not create the history symlink"
    [ "$(readlink -f "$sandbox/home/.bash_history")" = "$sandbox/gist/.bash_history" ] || fail "install.sh linked to the wrong file"
    grep -qx 'date' "$sandbox/gist/.bash_history" || fail "install.sh did not preserve the gist history"
    grep -qx 'local-command' "$sandbox/gist/.bash_history" || fail "install.sh did not append the local history"
    grep -Fq "$sandbox/backup.sh > $sandbox/backup.log 2>&1" "$sandbox/crontab.txt" || fail "install.sh did not write the backup command to crontab"
    if grep -Fq "sh $sandbox/backup.sh" "$sandbox/crontab.txt"; then
        fail "install.sh still wraps backup.sh with sh in crontab"
    fi
}

test_backup_rejects_truncation() {
    sandbox="$TMP_DIR/backup"
    mkdir -p "$sandbox/gist"
    cp "$ROOT_DIR/backup.sh" "$sandbox/"

    git init -q -b main "$sandbox/gist"
    git -C "$sandbox/gist" config user.name "Test User"
    git -C "$sandbox/gist" config user.email "test@example.com"
    git -C "$sandbox/gist" config commit.gpgsign false

    seq 1 2000 | sed 's/^/cmd-/' > "$sandbox/gist/.bash_history"
    git -C "$sandbox/gist" add .bash_history
    git -C "$sandbox/gist" commit -qm "Initial history"

    head -n 20 "$sandbox/gist/.bash_history" > "$sandbox/gist/.bash_history.tmp"
    mv "$sandbox/gist/.bash_history.tmp" "$sandbox/gist/.bash_history"

    if sh "$sandbox/backup.sh" > "$sandbox/output.txt" 2>&1; then
        fail "backup.sh accepted a destructive truncation"
    fi

    grep -Fq 'Refusing to back up a truncated .bash_history' "$sandbox/output.txt" || fail "backup.sh did not explain the truncation rejection"
    [ "$(git -C "$sandbox/gist" rev-list --count HEAD)" -eq 1 ] || fail "backup.sh created an unexpected commit"
}

test_install_preserves_existing_history
test_backup_rejects_truncation

echo "All regression tests passed"