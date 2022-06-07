#!/bin/bash

IS_GIT_AVAILABLE="$(git --version)"
if ! $IS_GIT_AVAILABLE == *"version"* ; then
    echo "Git is not installed"
    exit 1;
fi

# Check git status
gs="$(git status | grep -i "modified")"
echo "${gs}"

# If there is a new change
if [ ! $gs == *"modified"* ]; then
    echo "no changes"
    exit 1;
fi

cd $(pwd)/gist
git add .
git commit -m "New backup `date +'%Y-%m-%d %H:%M:%S'`"
git push origin main