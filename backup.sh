#!/bin/bash

IS_GIT_AVAILABLE="$(git --version)"
if ! $IS_GIT_AVAILABLE == *"version"* ; then
    echo "Git is not installed"
    exit 1;
fi

BASEDIR=$(dirname $0)/gist

# Check git status
HAVE_CHANGES="$(git -C $BASEDIR status --porcelain)"
if [[ $(git -C $BASEDIR status --porcelain | wc -c) -eq 0 ]] ; then
    echo "no changes"
    exit 1;
fi

git -C $BASEDIR add .
git -C $BASEDIR commit -m "New backup `date +'%Y-%m-%d %H:%M:%S'`"
git -C $BASEDIR push origin main