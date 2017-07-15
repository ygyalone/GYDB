#!/bin/bash
echo "here is old tags:"
git tag
echo "input a new tag:"
read tag
#replace version tag
sed -i "" "/s.version/s/=.*/= \"$tag\"/g" *.podspec
git add -A
git commit -m"update podspec with tag:$tag"
git push
pod trunk push *.podspec --allow-warnings --verbose

