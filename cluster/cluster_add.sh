#!/usr/bin/env bash

DEPLOY_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
TASKS_PATH=$DEPLOY_PATH/tasks
YAML_PATH=$DEPLOY_PATH/yaml

## TODO 引入clusterConfig配置文件
. $DEPLOY_PATH/../conf/clusterConfig
. $DEPLOY_PATH/../boot/cfg_node.sh
. $DEPLOY_PATH/../boot/cert/ssl_node.sh


## TODO 部署Kubernetes 集群
function DEPLOY_CLUSTER(){
    echo "Deploy kubernetes etcd........................."
    DEPLOY_ETCD
    echo "Deploy kubernetes MASTER........................."
    DEPLOY_MASTER
    echo "Deploy kubernetes rbac和dns........................."
    #本地启动kube-nginx
    echo "START KUBE-NGINX ON LOCAL........................."
    KUBE-NGINX-LOCAL
    echo "Deploy kubernetes RBAC........................."
    DEPLOY_RBAC_CLUSTER
    echo "Deploy kubernetes SLAVES........................."
    DEPLOY_SLAVES
}

## TODO 部署ETCD集群
function DEPLOY_ETCD(){
    nodes=${K8S_ETCD[@]}
    let len=${#K8S_ETCD[*]}
    read -p "Do you want to deploy etcd on [$nodes]?[Y/N/j]:" answer
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
    J | j)
    echo "Skip depoloy Kuberbetes etcd.";;        
    *)
        echo "Input error, please try again."
        exit 2;;
    esac
}

## TODO 部署MASTER集群
function DEPLOY_MASTER(){
    nodes=${K8S_MASTER[@]}
    let len=${#K8S_MASTER[*]}
    read -p "Do you want to deploy K8s-Master on [$nodes]?[Y/N/j]:" answer
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
    J | j)
    echo "Skip depoloy Kuberbetes master.";;      
    *)
        echo "Input error, please try again."
        exit 2;;
    esac
}

## TODO 部署SLAVE工作节点
function DEPLOY_SLAVES(){
    nodes=${K8S_SLAVES[@]}
    let len=${#K8S_SLAVES[*]}
    read -p "Do you want to deploy kubernetes node on [$nodes]?[Y/N/J]:" answer
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
    J | j)
    echo "Skip deploy Kuberbetes node.";;          
    *)
        echo "Input error, please try again."
        exit 2;;
    esac
    ADD_NODE_CLUSTER
}

#跳版机启动kube-nginx
function KUBE-NGINX-LOCAL() {
  #创建日志目录
  sudo mkdir -p /opt/kubernetes/kube-nginx/logs
  #创建nginx服务启动
  sudo cp /opt/kubernetes/cfg/kube-nginx.service /etc/systemd/system/kube-nginx.service
  #重新加载守护进程
  sudo systemctl daemon-reload
  #启动kube-nginx
  sudo systemctl start kube-nginx
}

function DEPLOY_RBAC_CLUSTER(){
   #生成node节点ssl证书
   echo "Start to create node ssl."
   SSL-NODE 
   #生成node节点cfg配置文件
   echo "Start to create node cfg."
   NODE-CFG

   ETCD_SERVERS=
   let len=${#K8S_ETCD[*]}
   for ((i=0; i<$len; i++))
   do
       let n=$i+1
       if [ "$len" -ne "$n" ]; then
        ETCD_SERVERS+="https://${K8S_ETCD[i]}:2379",
        continue
       fi
       ETCD_SERVERS+="https://${K8S_ETCD[i]}:2379"
       echo "K8S_ETCD"==[${ETCD_SERVERS}]
   done 
    
   ## 用etcd给Flannel分配网段
   /opt/kubernetes/bin/etcdctl \
     --endpoints=${ETCD_SERVERS} \
     --ca-file=/opt/kubernetes/ssl/ca.pem \
     --cert-file=/opt/kubernetes/ssl/flanneld.pem \
     --key-file=/opt/kubernetes/ssl/flanneld-key.pem \
     mk ${FLANNEL_ETCD_PREFIX}/config '{"Network":"'${CLUSTER_CIDR}'", "SubnetLen": 21, "Backend": {"Type": "vxlan"}}'

    kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --group=system:bootstrappers 
    kubectl apply -f $YAML_PATH/csr-crb.yaml
    kubectl apply -f $YAML_PATH/coredns.yaml
    
    #sleep 5m
    #kubectl get csr | grep Pending | awk '{print $1}' | xargs kubectl certificate approve
}

function ADD_NODE_CLUSTER(){
    kubectl get csr | grep Pending | awk '{print $1}' | xargs kubectl certificate approve
}