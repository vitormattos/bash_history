#!/bin/bash

if [ ! -L ~/.bash_history ]; then
    > gist/.bash_history
    cat ~/.bash_history >> gist/.bash_history
    ln -sf $(pwd)"/gist/.bash_history" ~/.bash_history
    echo "symlink created"
else
    ls -l ~/.bash_history
    echo "Check if the previous row is a link to your .bash_history in gist folder"
fi
(crontab -l 2>/dev/null; echo "*/1 * * * * sh $(pwd)/backup.sh > $(pwd)/backup.log 2>&1";) | crontab -
echo "Crontab created"
echo "Generating the fist backup..."
sh backup.sh