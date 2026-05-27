# .bash_history backup script

Never more lost your `.bash_history`

> **PS**: I can't solved a problem: the crontab haven't permission to get the ssh-agent. You will need push the gist directory manually.

## Explaning how this project work

The target is save your `.bash_history` into a secret gist.

Install script will:
* append your current `.bash_history` to `.bash_history` in your secret gist without truncating an existing backup
* delete your bash_history and create a simbolyc link to `.bash_history` from your secret gist
* configure crontab to run script `backup.sh` every 5 minutes
* configure your `~/.bashrc` to keep a large append-only history (`HISTSIZE`/`HISTFILESIZE`)

## Install

* Fork this repository
* Clone this repository in a place that you want
* go to cloned folder, probabily will be `bash_history`
* go to `gist.github.com`
* Create a secret gist with a file called `.bash_history` and put only the command `date` or other command. Isn't possible create an empty gist file
* Clone your secret gist using the follow command:
  ```bash
  git clone git@gist.github.com:<hash-of-your-gist>.git gist
  ```
* run:
  ```bash
  sh install.sh
  ```

### Install troubleshot

* Check if you have permission to commit and push to your gist file.
* Maybe you will need configure your ssh key in GitHub.
* Configure your name and email. The follow command can solve this problem replacing by your data:
```bash
git config user.name "Your Name" && git config user.email your@email.coop
```

## Recovery

If your current `.bash_history` shrank unexpectedly, your latest committed backup is still available in the local gist clone:

```bash
git -C gist show HEAD:.bash_history > recovered.bash_history
```

The backup script now refuses to auto-commit a destructive shrink, so a truncated history file will stop the backup instead of replacing the last good snapshot.

## Make .bash_history big
`install.sh` already adds this block automatically to your `~/.bashrc`.

If you prefer to configure it manually, add the follow lines to your `~/.bashrc`:
```bash
# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000000
unset HISTFILESIZE

# Save and reload the history after each command finishes
PROMPT_COMMAND="history -a; history -n; ${PROMPT_COMMAND:-}"

# Ensure history is saved before shell exits
trap 'history -a' EXIT
```

If you are fixing an already-open shell after restoring `~/.bash_history`, run `history -c && history -r` once to reload the current session from disk.

## To check if install executed fine:

* List user crontab file
  ```bash
  crontab -l
  ```
* Check simbolic link to `.bash_history` file
  ```
  stat ~/.bash_history
  # or run:
  ls -l ~/.bash_history
  ```
* After past 5 minutes from installing routine, check your git repository
