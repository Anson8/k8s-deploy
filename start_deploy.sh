#!/usr/bin/env bash
OPS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
echo $OPS_ROOT
## TODO 引入deployConfig配置文件
. $OPS_ROOT/config/clusterConfig
. $OPS_ROOT/boot/dog.sh

## TODO k8s服务器服务部署
options=("ipath" "deploy")
if [ $# -ne 1 ];then
	echo "Input invalid! Support: ipath | deploy"
	exit 1
fi

if [ $1 = "help" ];then
	echo "start_deploy.sh args: ipath | deploy"
	exit 0
fi

read -p "Are you sure to operate $1 Kuberbetes?[Y/N/J]:" answer
answer=$(echo $answer)
case $answer in
Y | y)
    echo "Start to operate $1 Kuberbetes node..."
    ## 初始化环境
    #PathInit
    ## SSL生成
    SSLGEN
    ;;
N | n)
    echo "Exit."
    exit 0;;
J | j)
    echo "Skip the operate $1 of the Kuberbetes.";;
*)
    echo "Input error, please try again."
    exit 1;;
esac