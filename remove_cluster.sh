#!/usr/bin/env bash
OPS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
echo $OPS_ROOT
## TODO 引入deployConfig配置文件
. $OPS_ROOT/cluster/cluster_rm.sh

## TODO k8s服务器初始化
read -p "Are you sure to remove Kuberbetes cluster?[Y/N/J]:" answer
answer=$(echo $answer)
case $answer in
Y | y)
    echo "Start to remove Kuberbetes cluster..."
    ## 移除node节点
    REMOVE_NODE
    ## 移除master节点
    REMOVE_MASTER
    ;;
N | n)
    echo "Exit."
    exit 0;;
J | j)
    echo "Skip the remove of the Kuberbetes."
    ;;
*)
    echo "Input error, please try again."
    exit 1;;
esac
