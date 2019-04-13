#!/bin/sh
#自动发布代码至beta环境,避免大量合并、tag及构建操作
#$1要合并的分支名,无则不传

cd ../

currentBranch=`git branch | grep '*' | sed "s/^* //g"`
if [ ${currentBranch} != 'master' ];then
    echo "请先切换至master分支！"
    exit
fi

git pull

#如果传了分支名,则合并分支并push,否则直接打tag
if [ -n "$1" ];then
    mergeBranch="origin/"$1
    git merge ${mergeBranch}
    git push origin master
fi

#打tag
tag="M"`date +"%Y%m%d%H%M%S"`
git tag ${tag}
git push origin ${tag}

cd publish-to-beta



#######################################准备构建beta环境
CONFIG_FILE=./publish.conf
COOKIE_FILE=./cookie.txt
userAgent="Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36"
retryNum=0

#构建
function build()
{
    buildUrl=`cat ${CONFIG_FILE} | grep 'buildUrl' | awk -F'buildUrl=' '{print($2)}'`
    crumb=`cat ${CONFIG_FILE} | grep 'Jenkins-Crumb' | awk -F'Jenkins-Crumb=' '{print($2)}'`
    buildData="name=tag&value=${tag}&statusCode=303&redirectTo=.&Jenkins-Crumb=${crumb}&json=%7B%22parameter%22%3A+%7B%22name%22%3A+%22tag%22%2C+%22value%22%3A+%22${tag}%22%7D%2C+%22statusCode%22%3A+%22303%22%2C+%22redirectTo%22%3A+%22.%22%2C+%22Jenkins-Crumb%22%3A+%22${crumb}%22%7D&Submit=%E5%BC%80%E5%A7%8B%E6%9E%84%E5%BB%BA"
    buildRes=`curl -d "${buildData}" -A "${userAgent}" -b "${COOKIE_FILE}" "${buildUrl}"`

    if [[ ${buildRes} =~ "403" ]];then
        echo "登录信息已过期,重新登录中..."
        doLogin

        if [[ ${retryNum} -eq 3 ]];then
            echo "重新登录超过3次,已自动退出！"
            exit
        fi

        build
    else
        echo "发布成功！tag为："${tag}
    fi
}

#登录
function doLogin()
{
    let retryNum=retryNum+1
	loginUrl=`cat ${CONFIG_FILE} | grep 'loginUrl' | awk -F'loginUrl=' '{print($2)}'`
	username=`cat ${CONFIG_FILE} | grep 'username' | awk -F'username=' '{print($2)}'`
	password=`cat ${CONFIG_FILE} | grep 'password' | awk -F'password=' '{print($2)}'`
	postData="j_username=${username}&j_password=${password}&from=%2F&Submit=%E7%99%BB%E5%BD%95"

	curl -d ${postData} -A "${userAgent}" -c "${COOKIE_FILE}" "${loginUrl}"
}

build
