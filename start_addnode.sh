#!/usr/bin/env bash
OPS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
echo $OPS_ROOT
## TODO 引入deployConfig配置文件
. $OPS_ROOT/conf/clusterConfig
. $OPS_ROOT/boot/dog.sh
. $OPS_ROOT/cluster/cluster_add_node.sh

## TODO k8s服务器新增节点
read -p "Are you sure to add node to $ENV Kuberbetes cluster?[Y/N/J]:" answer
answer=$(echo $answer)
case $answer in
Y | y)
    echo "Start to deploy node to $ENV Kuberbetes cluster..."
    ## 环境初始化
    PathInitSlaves
    ## 部署Node节点
    DEPLOY_CLUSTER
    ;;
N | n)
    echo "Exit."
    exit 0;;
J | j)
    echo "Skip to deploy node to $ENV Kuberbetes cluster.";;
*)
    echo "Input error, please try again."
    exit 1;;
esac