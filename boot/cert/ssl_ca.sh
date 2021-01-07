#!/usr/bin/env bash
DEPLOY_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
CONF_PATH=$DEPLOY_PATH/../../conf/clusterConfig

## TODO 引入deployConfig配置文件
. $DEPLOY_PATH/../../conf/clusterConfig
# 下载生成证书工具
function DownLoadCFSSL(){
  sudo mkdir -p /opt/kubernetes/{bin,cfg,ssl}
  sudo chown -R admin:admin /opt/kubernetes && cd /opt/kubernetes/ssl
  wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
  wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
  wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64

  chmod +x cfssl*
  sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
  sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
  sudo mv cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo
  
  export PATH=/usr/local/bin:$PATH
}

#生成根证书
function CreateCert-CA(){
  cd /opt/kubernetes/ssl
  cat > ca-config.json <<EOF
  {
    "signing": {
      "default": {
        "expiry": "87600h"
      },
      "profiles": {
        "kubernetes": {
           "expiry": "87600h",
           "usages": [
              "signing",
              "key encipherment",
              "server auth",
              "client auth"
          ]
        }
      }
    }
  }
EOF
  
  cat > ca-csr.json <<EOF
  {
      "CN": "kubernetes",
      "key": {
          "algo": "rsa",
          "size": 2048
      },
      "names": [
          {
              "C": "CN",
              "L": "Beijing",
              "ST": "Beijing",
              "O": "k8s",
              "OU": "System"
          }
      ]
  }
EOF
  
  cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

  #生成apiserver证书
  CreateCert-APISERVER
  #生成etcd证书
  CreateCert-ETCD
  #生成flannel证书
  CreateCert-FLANNEL
}

#生成apiserver服务使用
function CreateCert-APISERVER(){
  K8S_SERVERS=
  let len=${#K8S_MASTER[*]}
  for ((i=0; i<$len; i++))
  do
      let j=$i+1
      if [ "$len" -ne "$j" ]; then
       K8S_SERVERS+="\"${K8S_MASTER[i]}"\",
       continue
      fi
      K8S_SERVERS+="\"${K8S_MASTER[i]}"\"
      echo "K8S_MASTER"==[${K8S_SERVERS}]
  done
  cat > kubernetes-csr.json <<EOF
  {
    "CN": "kubernetes",
    "hosts": [
      "127.0.0.1",
      ${K8S_SERVERS},
      "${CLUSTER_KUBERNETES_SVC_IP}",
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local."
    ],
    "key": {
      "algo": "rsa",
      "size": 2048
    },
    "names": [
      {
        "C": "CN",
        "ST": "BeiJing",
        "L": "BeiJing",
        "O": "k8s",
        "OU": "4Paradigm"
      }
    ]
  }
EOF
}
#生成etcd证书,配置hosts 修改etcd集群IP
function CreateCert-ETCD(){
  K8S_SERVERS=
  let len=${#K8S_ETCD[*]}
  for ((i=0; i<$len; i++))
  do
      let j=$i+1
      if [ "$len" -ne "$j" ]; then
       K8S_SERVERS+="\"${K8S_ETCD[i]}"\",
       continue
      fi
      K8S_SERVERS+="\"${K8S_ETCD[i]}"\"
      echo "K8S_ETCD"==[${K8S_SERVERS}]
  done

  cat > etcd-csr.json <<EOF
  {
    "CN": "etcd",
    "hosts": [
      "127.0.0.1",
      ${K8S_SERVERS}
    ],
    "key": {
      "algo": "rsa",
      "size": 2048
    },
    "names": [
      {
        "C": "CN",
        "ST": "BeiJing",
        "L": "BeiJing",
        "O": "k8s",
        "OU": "4Paradigm"
      }
    ]
  }
EOF

cfssl gencert -ca=/opt/kubernetes/ssl/ca.pem \
    -ca-key=/opt/kubernetes/ssl/ca-key.pem \
    -config=/opt/kubernetes/ssl/ca-config.json \
    -profile=kubernetes etcd-csr.json | cfssljson -bare etcd
}

#生成Flannel证书，修改host node节点集群IP
function CreateCert-FLANNEL(){
  K8S_SERVERS=
  let len=${#K8S_SLAVES[*]}
  for ((i=0; i<$len; i++))
  do
      let j=$i+1
      if [ "$len" -ne "$j" ]; then
       K8S_SERVERS+="\"${K8S_SLAVES[i]}"\",
       continue
      fi
      K8S_SERVERS+="\"${K8S_SLAVES[i]}"\"
      echo "K8S_SLAVES"==[${K8S_SERVERS}]
  done

  cat > flanneld-csr.json <<EOF
  {
    "CN": "flanneld",
    "hosts": [
      ${K8S_SERVERS}
    ],
    "key": {
      "algo": "rsa",
      "size": 2048
    },
    "names": [
      {
        "C": "CN",
        "ST": "BeiJing",
        "L": "BeiJing",
        "O": "k8s",
        "OU": "4Paradigm"
      }
    ]
  }
EOF

cfssl gencert -ca=/opt/kubernetes/ssl/ca.pem \
    -ca-key=/opt/kubernetes/ssl/ca-key.pem \
    -config=/opt/kubernetes/ssl/ca-config.json \
    -profile=kubernetes flanneld-csr.json | cfssljson -bare flanneld
}

function RemovePem() {
  #保留.pem和ca文件删除其他文件
  cd /opt/kubernetes/ssl/
  ls |grep -v ca |grep -v pem |xargs -i rm {}
}