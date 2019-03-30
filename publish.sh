#!/bin/sh
#发布代码至beta环境,避免大量合并、tag及构建操作

cd ../

currentBranch=`git branch | grep '*' | sed "s/^* //g"`
if [ ${currentBranch} != 'master' ];then
    echo "请先切换至master分支！"
    exit
fi
git pull




#if [ -n "$1" ];then
#    echo 'YOUZHI'
#else
#    echo 'NONONO'
#fi
