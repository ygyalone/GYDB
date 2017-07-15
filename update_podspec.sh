#!/bin/bash
#push changes to remote git lib
function gitPush() {
    git add -A
    git commit -m"update podspec with tag:$tag"
    git tag $1
    git push
    git push --tags
}

#push new podSpec to cocoapods
function podPush() {
    pod trunk push *.podspec --allow-warnings --verbose
}

#green color echo
function greenEcho() {
    echo -e "\033[32m$1\033[0m"
}

#red color echo
function redEcho() {
    echo -e "\033[31m$1\033[0m"
}


#read tag
greenEcho "here is old tags:"
git tag
greenEcho "input a new tag:"
read tag

#pod trunk命令需要先注册,所以在更新版本前先判断是否注册,该条命令不在屏幕上显示
pod trunk me > /dev/null
if [ $? -ne 0 ]
then
#{ "GuangYuYang" => "ygy9916730@163.com" }
    redEcho "pod trunk not registered!"
    redEcho "you should run this command before push podSpec to cocoapods:"
    redEcho "pod trunk register example@mail.com 'authorName'"
    exit
fi

#replace version tag
sed -i "" "/s.version/s/=.*/= \"$tag\"/g" *.podspec

gitPush $tag
podPush


