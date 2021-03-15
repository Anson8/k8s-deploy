#!/usr/bin/env bash
OPS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
echo $OPS_ROOT
## TODO 引入deployConfig配置文件
. $OPS_ROOT/conf/clusterConfig
. $OPS_ROOT/boot/dog.sh
. $OPS_ROOT/cluster/cluster.sh

## TODO k8s服务器初始化
read -p "Are you sure to Init $1 Kuberbetes?[Y/N/J]:" answer
answer=$(echo $answer)
case $answer in
Y | y)
    echo "Start to Init $1 Kuberbetes cluster..."
    ## 生成证书&配置文件
    SSL-CFG
    ## 集群环境初始化
    #PathInit
    ## 集群部署
    #DEPLOY_CLUSTER
    ;;
N | n)
    echo "Exit."
    exit 0;;
J | j)
    echo "Skip the Init $1 of the Kuberbetes.";;
*)
    echo "Input error, please try again."
    exit 1;;
esac

## TODO k8s服务器服务部署
read -p "Are you sure to depoloy $1 Kuberbetes?[Y/N/J]:" answer
answer=$(echo $answer)
case $answer in
Y | y)
    echo "Start to depoloy Kuberbetes Master in $1 cluster..."
    DEPLOY_CLUSTER
    ;;
N | n)
    echo "Exit."
    exit 0;;
J | j)
    echo "Skip depoloy Kuberbetes etcd in $1 of the Kuberbetes.";;
*)
    echo "Input error, please try again."
    exit 1;;
esac