#!/usr/bin/env bash

DEPLOY_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
TASKS_PATH=$DEPLOY_PATH/tasks
## TODO 引入clusterConfig配置文件
. $DEPLOY_PATH/../conf/clusterConfig

## TODO 部署Kubernetes 集群
function DEPLOY_CLUSTER(){
    #DEPLOY_ETCD
    DEPLOY_MASTER
    #DEPLOY_SLAVES
    # 部署dns服务
    #kubectl create -f yaml/coredns.yaml
    # 工作节点纳入集群
    # kubectl apply -f yaml/csr-crb.yaml
    # sleep 5m
    # kubectl get csr | grep Pending | awk '{print $1}' | xargs kubectl certificate approve
}

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
            ##  部署etcd
            echo "ansible-playbook deploy etcd on this ${K8S_ETCD[i]}"
            ansible-playbook $TASKS_PATH/etcd.yml -i ${K8S_ETCD[i]}, -e "n=$n" --private-key=/home/admin/.ssh/$PRIVATEKEY
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
    read -p "Do you want to deploy K8s-Master on [$nodes]?[Y/N]:" answer
    answer=$(echo $answer)
    case $answer in
    Y | y)
        echo "Start to deploy kubernetes Master."
        for ((i=0; i<$len; i++))
        do
          let n=$i+1
            ##  部署kube-apiserver
            echo "ansible-playbook deploy kube-apiserver on this ${K8S_MASTER[i]}"
            ansible-playbook $TASKS_PATH/kube-apiserver.yml -i ${K8S_MASTER[i]}, -e "K8S_DIR=$K8S_DIR n=$n" --private-key=/home/admin/.ssh/$PRIVATEKEY
            ##  部署kube-nginx
            echo "ansible-playbook deploy kube-nginx on this ${K8S_MASTER[i]}"
            ansible-playbook $TASKS_PATH/kube-nginx.yml -i ${K8S_MASTER[i]},  --private-key=/home/admin/.ssh/$PRIVATEKEY
            ##  部署kube-controller-manager
            echo "ansible-playbook deploy kube-controller-manager on this ${K8S_MASTER[i]}"
            ansible-playbook $TASKS_PATH/kube-controller-manager.yml -i ${K8S_MASTER[i]}, -e "K8S_DIR=$K8S_DIR n=$n" --private-key=/home/admin/.ssh/$PRIVATEKEY
            ##  部署kube-scheduler
            echo "ansible-playbook deploy kube-scheduler on this ${K8S_MASTER[i]}"
            ansible-playbook $TASKS_PATH/kube-scheduler.yml -i ${K8S_MASTER[i]}, -e "K8S_DIR=$K8S_DIR n=$n" --private-key=/home/admin/.ssh/$PRIVATEKEY

            if [ $? -ne 0 ];then
                 echo "Deploy K8s-Master on $ip..................Failed! Ret=$ret"
                return 1
            fi
        done
        echo "Deploy K8s-Master ...................Successfully!";;
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
            ##  部署kube-nginx
            echo "ansible-playbook deploy kube-nginx on this ${K8S_SLAVES[i]}"
            ansible-playbook $TASKS_PATH/kube-nginx.yml -i ${K8S_SLAVES[i]},  --private-key=/home/admin/.ssh/$PRIVATEKEY
            ##  部署kubelet
            echo "ansible-playbook deploy kubelet on this ${K8S_ETCD[i]}"
            ansible-playbook $TASKS_PATH/kubeletyml -i ${K8S_ETCD[i]}, -e "n=$n" --private-key=/home/admin/.ssh/$PRIVATEKEY
            ##  部署kube-proxy
            echo "ansible-playbook deploy kube-proxy on this ${K8S_ETCD[i]}"
            ansible-playbook $TASKS_PATH/kube-proxy.yml -i ${K8S_ETCD[i]}, -e "n=$n" --private-key=/home/admin/.ssh/$PRIVATEKEY
            ##  部署flanneld
            echo "ansible-playbook deploy flanneld on this ${K8S_SLAVES[i]}"
            ansible-playbook $TASKS_PATH/flanneld.yml -i ${K8S_SLAVES[i]}, --private-key=/home/admin/.ssh/$PRIVATEKEY
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