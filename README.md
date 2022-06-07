# .bash_history backup script

Never more lost your `.bash_history`

## Explaning how this project work

The target is save your `.bash_history` into a secret gist.

Install script will:
* append your current `.bash_history` to bash_history of your secret gist
* delete your bash_history and create a simbolyc link to bash_history from your secret gist
* configure crontab to run script `backup.sh` every 5 minutes

## Install

* Fork this repository
* Clone this repository in a place that you want
* go to cloned folder, probabily will be `bash_history`
* go to `gist.github.com`
* Create a secret gist with a file called `bash_history` and put only the command `date` or other commant. Isn't possible create an empty gist file
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

## Make .bash_history big
Add the follow lines to your `~/.bashrc`
```bash
# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000000
HISTFILESIZE=2000000

# Save and reload the history after each command finishes
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
```

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
