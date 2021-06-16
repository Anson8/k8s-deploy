#!/usr/bin/env bash

DEPLOY_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
TASKS_PATH=$DEPLOY_PATH/tasks


## TODO 引入clusterConfig配置文件
. $DEPLOY_PATH/../conf/clusterConfig
. $DEPLOY_PATH/../boot/cfg_node.sh
. $DEPLOY_PATH/../boot/cert/ssl_node.sh


## TODO 部署新增Node节点
function DEPLOY_CLUSTER(){
    echo "Create Node ssl and cfg........................."
    DEPLOY_NODE_SSL_CFG
    echo "Deploy kubernetes SLAVES."
    DEPLOY_SLAVES
}

## TODO 部署SLAVE工作节点
function DEPLOY_SLAVES(){
    nodes=${K8S_SLAVES[@]}
    let len=${#K8S_SLAVES[*]}
    read -p "Do you want to deploy kubernetes node on [$nodes]?[Y/N]:" answer
    answer=$(echo $answer)
    case $answer in
    Y | y)
        echo "Start to deploy kubernetes node."
        for ((i=0; i<$len; i++))
        do
          let n=$i+1
            ##  部署kube-nginx
            echo "ansible-playbook deploy kube-nginx on this ${K8S_SLAVES[i]}"
            ansible-playbook $TASKS_PATH/kube-nginx.yml -i ${K8S_SLAVES[i]},  --private-key=/home/admin/.ssh/$PRIVATEKEY
            ##  部署kubelet
            echo "ansible-playbook deploy kubelet on this ${K8S_SLAVES[i]}"
            ansible-playbook $TASKS_PATH/kubelet.yml -i ${K8S_SLAVES[i]}, -e "n=${HOST_NAMES[$i]}" --private-key=/home/admin/.ssh/$PRIVATEKEY
            ##  部署kube-proxy
            echo "ansible-playbook deploy kube-proxy on this ${K8S_SLAVES[i]}"
            ansible-playbook $TASKS_PATH/kube-proxy.yml -i ${K8S_SLAVES[i]}, -e "n=${HOST_NAMES[$i]}" --private-key=/home/admin/.ssh/$PRIVATEKEY
            ##  部署flanneld
            echo "ansible-playbook deploy flanneld on this ${K8S_SLAVES[i]}"
            ansible-playbook $TASKS_PATH/flanneld.yml -i ${K8S_SLAVES[i]}, --private-key=/home/admin/.ssh/$PRIVATEKEY

            if [ $? -ne 0 ];then
                 echo "Deploy kubernetes node on $ip..................Failed! Ret=$ret"
                return 1
            fi
        done
        echo "Deploy kubernetes node ...................Successfully!";;
    N | n)
        echo "Exit."
        exit 0;;
    *)
        echo "Input error, please try again."
        exit 2;;
    esac
    ADD_NODE_CLUSTER
}

function DEPLOY_NODE_SSL_CFG(){
   #生成node节点ssl证书
   echo "Start to create node ssl."
   SSL-NODE
   #生成node节点cfg配置文件
   echo "Start to create node cfg."
   NODE-CFG
}

function ADD_NODE_CLUSTER(){
    kubectl get csr | grep Pending | awk '{print $1}' | xargs kubectl certificate approve
}