#!/usr/bin/env bash

DEPLOY_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
TASKS_PATH=$DEPLOY_PATH/tasks
## TODO 引入deployConfig配置文件
. $DEPLOY_PATH/../conf/clusterConfig
. $DEPLOY_PATH/cert/ssl-ca.sh

## TODO 部署Kubernetes Node节点
function PathInit(){
    # 初始化master节点环境
    masters=${K8S_MASTER[@]}
    read -p "Do you want to init master path on all [$nodes] nodes?[Y/N]:" answer
    answer=$(echo $answer)
    let m=1
    case $answer in
    Y | y)
        echo "Start to init kubernetes master path."
        for ip in $masters;
        do
            hname=master+"0"+m
            echo "ansible-playbook init kubernetes master path on this $ip"
            ansible-playbook $TASKS_PATH/bootstrap.yaml -i $ip, -e "hostname=$hname  ansible_user=$USER ansible_ssh_pass=$PASSWD ansible_become_pass=$PASSWD"
            echo "ansible-playbook install docker"
            ansible-playbook $TASKS_PATH/docker_install.yml -i $ip, -e "docker_version=$DOCKER_VERSION  ansible_user=$USER ansible_ssh_pass=$PASSWD ansible_become_pass=$PASSWD"
            if [ $? -ne 0 ];then
                 echo "Init kubernetes master $ip path...................Failed! Ret=$ret"
                return 1
            fi
        done
        m=$(($m+1))
        echo "Init kubernetes master $ip path...................Successfully!";;
    N | n)
        echo "Exit."
        exit 0;;
    *)
        echo "Input error, please try again."
        exit 2;;
    esac
    # 初始化slaves节点环境
    slaves=${K8S_SLAVES[@]}
    read -p "Do you want to init slave path on all [$nodes] nodes?[Y/N]:" answer
    answer=$(echo $answer)
    let m=1
    case $answer in
    Y | y)
        echo "Start to init kubernetes slave path."
        for ip in $masters;
        do
            hname=slave+"0"+m
            echo "ansible-playbook init kubernetes slave path on this $ip"
            ansible-playbook $TASKS_PATH/bootstrap.yaml -i $ip, -e "hostname=$hname  ansible_user=$USER ansible_ssh_pass=$PASSWD ansible_become_pass=$PASSWD"
            echo "ansible-playbook install docker"
            ansible-playbook $TASKS_PATH/docker_install.yml -i $ip, -e "docker_version=$DOCKER_VERSION  ansible_user=$USER ansible_ssh_pass=$PASSWD ansible_become_pass=$PASSWD"
            if [ $? -ne 0 ];then
                 echo "Init kubernetes slave $ip path...................Failed! Ret=$ret"
                return 1
            fi
        done
        m=$(($m+1))
        echo "Init kubernetes slave $ip path...................Successfully!";;
    N | n)
        echo "Exit."
        exit 0;;
    *)
        echo "Input error, please try again."
        exit 2;;
    esac
}

## TODO: 证书生成
function SSLGEN(){
    read -p "Do you want to create ssl ?[Y/N]:" answer
    answer=$(echo $answer)
    case $answer in
    Y | y)
        echo "Start to create ssl."
        # 下载生成证书工具
        echo "Start to download cfssl_linux-amd64."
        #DownLoadCFSSL
        #生成证书
        echo "Start to create ca-cert."
        CreateCert-CA
        #保留.pem文件删除其他文件
        echo "Start to rm .pem."
        #RemovePem
        echo "Create ssl $ip path...................Successfully!";;
    N | n)
        echo "Exit."
        exit 0;;
    *)
        echo "Input error, please try again."
        exit 2;;
    esac
}