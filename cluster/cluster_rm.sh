#!/usr/bin/env bash

DEPLOY_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
TASKS_PATH=$DEPLOY_PATH/tasks
## TODO 引入clusterConfig配置文件
. $DEPLOY_PATH/../conf/clusterConfig



## TODO 移除集群Node节点
function REMOVE_NODE(){
    # 获取node节点ip
    nodes=${K8S_SLAVES[@]}
    read -p "Do you want to remove node [$nodes] on k8s cluster?[Y/N]:" answer
    answer=$(echo $answer)
    case $answer in
    Y | y)
        echo "Start to remove node."
        for ip in $nodes;
        do
            echo "ansible-playbook remove node $ip"
            ansible-playbook $TASKS_PATH/remove_node.yml -i $ip, --private-key=/home/admin/.ssh/$PRIVATEKEY
            if [ $? -ne 0 ];then
                 echo "remove node $ip path...................Failed! Ret=$ret"
                return 1
            fi
        done
        echo "remove node $ip path...................Successfully!";;
    N | n)
        echo "Exit."
        exit 0;;
    *)
        echo "Input error, please try again."
        exit 2;;
    esac
}

## TODO 移除集群Master节点
function REMOVE_MASTER(){
    # 获取master节点ip
    nodes=${K8S_MASTER[@]}
    read -p "Do you want to remove master [$nodes] on k8s cluster?[Y/N]:" answer
    answer=$(echo $answer)
    case $answer in
    Y | y)
        echo "Start to remove master."
        for ip in $nodes;
        do
            echo "ansible-playbook remove master $ip"
            ansible-playbook $TASKS_PATH/remove_master.yml -i $ip, --private-key=/home/admin/.ssh/$PRIVATEKEY
            if [ $? -ne 0 ];then
                 echo "remove master $ip path...................Failed! Ret=$ret"
                return 1
            fi
        done
        echo "remove master $ip path...................Successfully!";;
    N | n)
        echo "Exit."
        exit 0;;
    *)
        echo "Input error, please try again."
        exit 2;;
    esac
}
