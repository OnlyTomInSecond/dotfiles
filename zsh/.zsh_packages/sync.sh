#!/bin/bash
#

GIT_URL=("https://github.com/zdharma-continuum/fast-syntax-highlighting" "https://github.com/romkatv/powerlevel10k.git" "https://github.com/sindresorhus/pure.git" "https://github.com/zsh-users/zsh-autosuggestions.git" "https://github.com/zsh-users/zsh-completions.git" "https://github.com/zsh-users/zsh-syntax-highlighting")

dirs=$(ls)

sync(){
    for dir in ${dirs}
    do
        if [ -d ${dir} ];then
            cd $dir
            git pull
            git reflog expire --expire=now --expire-unreachable=now --all
            git gc --prune=now
            cd ..
        fi
    done
}

download(){
    for i in "${GIT_URL[@]}";do
        echo "clone ${i}"
        git clone "${i}"
    done
}

if [ "$1" == "download" ];then
    download
elif [ "$1" == "sync" ];then
    sync
else
    echo "sync.sh [download|sync]"
fi

