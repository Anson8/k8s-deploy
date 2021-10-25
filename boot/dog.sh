#!/usr/bin/env bash

DEPLOY_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
BOOT_TASKS_PATH=$DEPLOY_PATH/tasks
## TODO 引入deployConfig配置文件
. $DEPLOY_PATH/../conf/clusterConfig
. $DEPLOY_PATH/cfg_master.sh
. $DEPLOY_PATH/cert/ssl_ca.sh

## TODO 部署Kubernetes Node节点
function PathInit(){
    # 生成证书
    SSL-CFG
    # 初始化master节点环境
    PathInitMaster
    # 初始化node节点环境
    PathInitSlaves    
}

## TODO: 证书&&配置文件生成
function SSL-CFG(){
    read -p "Do you want to create ssl ?[Y/N/J]:" answer
    answer=$(echo $answer)
    case $answer in
    Y | y)
        #生成证书
        echo "Start to create ssl."
        CREATE-SSL
        #生成cfg配置文件
        echo "Start to create masetr cfg."
        MASTER-CFG
        #保留.pem文件删除其他文件
        echo "Start to rm .pem."
        #RemovePem
        echo "Create ssl $ip path...................Successfully!";;
    N | n)
        echo "Exit."
        exit 0;;
    J | j)
        echo "Skip the ssl $1 of the Kuberbetes.";;          
    *)
        echo "Input error, please try again."
        exit 2;;
    esac
}

## TODO 部署Kubernetes Master节点
function PathInitMaster(){
    # 初始化master节点环境
    nodes=${K8S_MASTER[@]}
    read -p "Do you want to init master path on all [$nodes] nodes?[Y/N/J]:" answer
    answer=$(echo $answer)
    let m=1
    case $answer in
    Y | y)
        echo "Start to init kubernetes master path."
        for ip in $nodes;
        do
            hname=k8s-master+"0"$m
            echo "Start to add [$ip] to known_hosts."
            ssh-keyscan -H $ip >> ~/.ssh/known_hosts
            echo "ansible-playbook create user admin on this $ip"
            ansible-playbook $BOOT_TASKS_PATH/createuser.yml -i $ip, -e "pubkey=$PRIVATEKEY user_add=$USER ansible_user=$USER_INIT ansible_ssh_pass=$PASSWD_INIT ansible_become_pass=$PASSWD_INIT condition=false"
            echo "ansible-playbook mount disk on this $ip"
            ansible-playbook $BOOT_TASKS_PATH/diskpart.yml  -i $ip, -e "user_add=$USER  disk=$DISK diskfullpath=$DISKFULLPATH" --private-key=/home/admin/.ssh/$PRIVATEKEY
            echo "ansible-playbook init kubernetes master path on this $ip"
            ansible-playbook $BOOT_TASKS_PATH/bootstrap.yml -i $ip, -e "hostname=$hname" --private-key=/home/admin/.ssh/$PRIVATEKEY
            sleep 30s;
            echo "ansible-playbook install docker"
            ansible-playbook $BOOT_TASKS_PATH/docker_install.yml -i $ip, -e "docker_version=$DOCKER_VERSION" --private-key=/home/admin/.ssh/$PRIVATEKEY
            if [ $? -ne 0 ];then
                 echo "Init kubernetes master $ip path...................Failed! Ret=$ret"
                return 1
            fi
            m=$(($m+1))
        done
        echo "Init kubernetes master $ip path...................Successfully!";;
    N | n)
        echo "Exit."
        exit 0;;
    J | j)
        echo "Skip the operate $1 of the Kuberbetes.";;            
    *)
        echo "Input error, please try again."
        exit 2;;
    esac
}

## TODO 部署Kubernetes Node节点
function PathInitSlaves(){
    # 拷贝相关环境证书
    #mkdir -p /opt/kubernetes/{cfg,ssl}
    rm -rf /opt/kubernetes/{ssl,cfg} 
    cp -R /opt/k8s-cfg/$ENV/{ssl,cfg} /opt/kubernetes
    cp /opt/k8s-cfg/$ENV/kubectl.kubeconfig  ~/.kube/config
    sudo systemctl restart kube-nginx
    # 初始化slaves节点环境
    nodes=${K8S_SLAVES[@]}
    read -p "Do you want to init slave path on all [$nodes] nodes?[Y/N/J]:" answer
    answer=$(echo $answer)
    let m=1
    case $answer in
    Y | y)
        echo "Start to init kubernetes slave path."
        for ip in $nodes;
        do
            hname=${HOST_NAMES[$i]}
            echo "Start to add [$ip] to known_hosts."
            ssh-keyscan -H $ip >> ~/.ssh/known_hosts
            echo "ansible-playbook create user admin on this $ip"
            ansible-playbook $BOOT_TASKS_PATH/createuser.yml -i $ip, -e "pubkey=$PRIVATEKEY user_add=$USER ansible_user=$USER_INIT ansible_ssh_pass=$PASSWD_INIT ansible_become_pass=$PASSWD_INIT condition=false"
            echo "ansible-playbook mount disk on this $ip"
            ansible-playbook $BOOT_TASKS_PATH/diskpart.yml  -i $ip, -e "user_add=$USER  disk=$DISK diskfullpath=$DISKFULLPATH" --private-key=/home/admin/.ssh/$PRIVATEKEY
            echo "ansible-playbook init kubernetes slave path on this $ip"
            ansible-playbook $BOOT_TASKS_PATH/bootstrap.yml -i $ip, -e "hostname=$hname" --private-key=/home/admin/.ssh/$PRIVATEKEY
            echo "ansible-playbook install docker $DOCKER_VERSION"
            ansible-playbook $BOOT_TASKS_PATH/docker_install.yml -i $ip, -e "docker_version=$DOCKER_VERSION docker_compose_v=$DOCKER_COMPOSE_VERSION" --private-key=/home/admin/.ssh/$PRIVATEKEY
            if [ $? -ne 0 ];then
                 echo "Init kubernetes slave $ip path...................Failed! Ret=$ret"
                return 1
            fi
            m=$(($m+1))
        done
        echo "Init kubernetes slave $ip path...................Successfully!";;
    N | n)
        echo "Exit."
        exit 0;;
    J | j)
        echo "Skip the init path $1 of the Kuberbetes.";;           
    *)
        echo "Input error, please try again."
        exit 2;;
    esac
}