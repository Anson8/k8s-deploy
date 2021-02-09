#!/usr/bin/env bash

DEPLOY_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
TASKS_PATH=$DEPLOY_PATH/tasks
## TODO 引入clusterConfig配置文件
. $DEPLOY_PATH/../conf/clusterConfig

## TODO 部署Kubernetes 集群

## TODO 部署ETCD集群
function DEPLOY_ETCD(){
    nodes=${K8S_ETCD[@]}
    let len=${#K8S_ETCD[*]}
    read -p "Do you want to deploy etcd on [$nodes]?[Y/N]:" answer
    answer=$(echo $answer)
    case $answer in
    Y | y)
        echo "Start to deploy kubernetes etcd."
        for ((i=0; i<$len; i++))
        do
          let n=$i+1
            echo "ansible-playbook deploy etcd on this ${K8S_ETCD[i]}"
            ansible-playbook $TASKS_PATH/etcd.yml -i ${K8S_ETCD[i]}, -e "etcd_n=$n etcd_data=$ETCD_DATA_DIR etcd_awl=$ETCD_WAL_DIR" --private-key=/home/admin/.ssh/$PRIVATEKEY
            if [ $? -ne 0 ];then
                 echo "Deploy etcd on $ip..................Failed! Ret=$ret"
                return 1
            fi
        done
        echo "Deploy etcd ...................Successfully!";;
    N | n)
        echo "Exit."
        exit 0;;
    *)
        echo "Input error, please try again."
        exit 2;;
    esac
}

## TODO 部署MASTER集群
function DEPLOY_MASTER(){
    nodes=${K8S_MASTER[@]}
    let len=${#K8S_MASTER[*]}
    read -p "Do you want to deploy etcd on [$nodes]?[Y/N]:" answer
    answer=$(echo $answer)
    case $answer in
    Y | y)
        echo "Start to deploy kubernetes etcd."
        for ((i=0; i<$len; i++))
        do
          let n=$i+1
            echo "ansible-playbook deploy etcd on this ${K8S_MASTER[i]}"
            ansible-playbook $TASKS_PATH/etcd.yml -i ${K8S_MASTER[i]}, -e "etcd_n=$n etcd_data=$ETCD_DATA_DIR etcd_awl=$ETCD_WAL_DIR" --private-key=/home/admin/.ssh/$PRIVATEKEY
            if [ $? -ne 0 ];then
                 echo "Deploy etcd on $ip..................Failed! Ret=$ret"
                return 1
            fi
        done
        echo "Deploy etcd ...................Successfully!";;
    N | n)
        echo "Exit."
        exit 0;;
    *)
        echo "Input error, please try again."
        exit 2;;
    esac
}

## TODO 部署SLAVE工作节点
function DEPLOY_SLAVES(){
    nodes=${K8S_SLAVES[@]}
    let len=${#K8S_SLAVES[*]}
    read -p "Do you want to deploy etcd on [$nodes]?[Y/N]:" answer
    answer=$(echo $answer)
    case $answer in
    Y | y)
        echo "Start to deploy kubernetes etcd."
        for ((i=0; i<$len; i++))
        do
          let n=$i+1
            echo "ansible-playbook deploy etcd on this ${K8S_SLAVES[i]}"
            ansible-playbook $TASKS_PATH/etcd.yml -i ${K8S_SLAVES[i]}, -e "etcd_n=$n etcd_data=$ETCD_DATA_DIR etcd_awl=$ETCD_WAL_DIR" --private-key=/home/admin/.ssh/$PRIVATEKEY
            if [ $? -ne 0 ];then
                 echo "Deploy etcd on $ip..................Failed! Ret=$ret"
                return 1
            fi
        done
        echo "Deploy etcd ...................Successfully!";;
    N | n)
        echo "Exit."
        exit 0;;
    *)
        echo "Input error, please try again."
        exit 2;;
    esac
}