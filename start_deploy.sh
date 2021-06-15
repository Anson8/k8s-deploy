#!/usr/bin/env bash
OPS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
echo $OPS_ROOT
## TODO 引入deployConfig配置文件
. $OPS_ROOT/conf/clusterConfig
. $OPS_ROOT/boot/dog.sh
. $OPS_ROOT/cluster/cluster_add.sh
. $OPS_ROOT/cluster/cluster_add_node.sh

## TODO k8s服务器初始化
read -p "Are you sure to Init $1 Kuberbetes?[Y/N/J]:" answer
answer=$(echo $answer)
case $answer in
Y | y)
    echo "Start to Init $1 Kuberbetes cluster..."
    ## 集群环境初始化
    PathInit
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
read -p "Are you sure to depoly $1 Kuberbetes?[Y/N/J]:" answer
answer=$(echo $answer)
case $answer in
Y | y)
    echo "Start to depoly Kuberbetes Master in $1 cluster..."
    ## 集群部署
    DEPLOY_CLUSTER
    ;;
N | n)
    echo "Exit."
    exit 0;;
J | j)
    echo "Skip depoly Kuberbetes  in $1 of the Kuberbetes.";;
*)
    echo "Input error, please try again."
    exit 1;;
esac

## TODO k8s服务器新增节点
read -p "Are you sure to add node in Kuberbetes?[Y/N/J]:" answer
answer=$(echo $answer)
case $answer in
Y | y)
    echo "Start to deploy Kuberbetes node in cluster..."
    ## 环境初始化
    PathInitSlaves
    ## 部署Node节点
    DEPLOY_CLUSTER
    ;;
N | n)
    echo "Exit."
    exit 0;;
J | j)
    echo "Skip depoly Kuberbetes node in the Kuberbetes.";;
*)
    echo "Input error, please try again."
    exit 1;;
esac