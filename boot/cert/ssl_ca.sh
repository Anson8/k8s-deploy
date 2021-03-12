#!/usr/bin/env bash
DEPLOY_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
CONF_PATH=$DEPLOY_PATH/../../conf/clusterConfig

## TODO 引入deployConfig配置文件
. $DEPLOY_PATH/../../conf/clusterConfig
# 下载生成证书工具
function DownLoadCFSSL(){
  sudo mkdir -p /opt/kubernetes/{bin,cfg,ssl}
  sudo chown -R admin:admin /opt/kubernetes
  cd /opt/kubernetes/ssl
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
  #cd /opt/kubernetes/bin
  #chmod +x cfssl*
  #sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
  #sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
  #sudo mv cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo
  #export PATH=/usr/local/bin:$PATH

  cd /opt/kubernetes/ssl
  cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
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
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "4Paradigm"
    }
  ],
  "ca": {
    "expiry": "876000h"
 }
}
EOF
  
  cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

  #生成apiserver证书
  CreateCert-APISERVER
  #生成etcd证书
  CreateCert-ETCD
  #生成flannel证书
  CreateCert-FLANNEL
  #生成kube-admin证书
  KUBE-ADMIN
  PROXY-CLIENT
  KUBE-CONTROLLER_MANAGER
  KUBE-SCHEDULER
}

#生成kube-admin证书
function KUBE-ADMIN(){
cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "system:masters",
      "OU": "4Paradigm"
    }
  ]
}
EOF

cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "system:masters",
      "OU": "4Paradigm"
    }
  ]
}
EOF

cfssl gencert -ca=/opt/kubernetes/ssl/ca.pem \
  -ca-key=/opt/kubernetes/ssl/ca-key.pem \
  -config=/opt/kubernetes/ssl/ca-config.json \
  -profile=kubernetes admin-csr.json | cfssljson -bare admin

sudo cp /opt/kubernetes/bin/kubectl /usr/local/bin/

kubectl config set-cluster kubernetes \
  --certificate-authority=/opt/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kubectl.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=/opt/kubernetes/ssl/admin.pem \
  --client-key=/opt/kubernetes/ssl/admin-key.pem \
  --embed-certs=true \
  --kubeconfig=kubectl.kubeconfig

kubectl config set-context kubernetes \
  --cluster=kubernetes \
  --user=admin \
  --kubeconfig=kubectl.kubeconfig

kubectl config use-context kubernetes --kubeconfig=kubectl.kubeconfig

mkdir ~/.kube
cp kubectl.kubeconfig ~/.kube/config

}

#生成kubernetes证书，apiserver服务使用
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
cfssl gencert -ca=/opt/kubernetes/ssl/ca.pem \
  -ca-key=/opt/kubernetes/ssl/ca-key.pem \
  -config=/opt/kubernetes/ssl/ca-config.json \
  -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes
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
    
## 用etcd给Flannel分配网段
/opt/kubernetes/bin/etcdctl \
  --endpoints=${ETCD_ENDPOINTS} \
  --ca-file=/opt/kubernetes/ssl/ca.pem \
  --cert-file=/opt/kubernetes/ssl/flanneld.pem \
  --key-file=/opt/kubernetes/ssl/flanneld-key.pem \
  mk ${FLANNEL_ETCD_PREFIX}/config '{"Network":"'${CLUSTER_CIDR}'", "SubnetLen": 21, "Backend": {"Type": "vxlan"}}'
}

#生成proxy-client证书
function PROXY-CLIENT(){
  cat > proxy-client-csr.json <<EOF
{
  "CN": "aggregator",
  "hosts": [],
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
    -profile=kubernetes proxy-client-csr.json | cfssljson -bare proxy-client
}

#生成kube-controller-manager配置文件
function KUBE-CONTROLLER_MANAGER(){
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
  cat > kube-controller-manager-csr.json <<EOF
  {
    "CN": "system:kube-controller-manager",
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
        "O": "system:kube-controller-manager",
        "OU": "4Paradigm"
      }
    ]
  }
EOF

cfssl gencert -ca=/opt/kubernetes/ssl/ca.pem \
  -ca-key=/opt/kubernetes/ssl/ca-key.pem \
  -config=/opt/kubernetes/ssl/ca-config.json \
  -profile=kubernetes kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

kubectl config set-cluster kubernetes \
  --certificate-authority=/opt/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=kube-controller-manager.pem \
  --client-key=kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context system:kube-controller-manager \
  --cluster=kubernetes \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig  

}

#生成kube-scheduler配置文件
function KUBE-SCHEDULER(){
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
  cat > kube-scheduler-csr.json <<EOF
  {
    "CN": "system:kube-scheduler",
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
        "O": "system:kube-scheduler",
        "OU": "4Paradigm"
      }
    ]
  }
EOF

cfssl gencert -ca=/opt/kubernetes/ssl//ca.pem \
  -ca-key=/opt/kubernetes/ssl//ca-key.pem \
  -config=/opt/kubernetes/ssl//ca-config.json \
  -profile=kubernetes kube-scheduler-csr.json | cfssljson -bare kube-scheduler


kubectl config set-cluster kubernetes \
  --certificate-authority=/opt/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=kube-scheduler.pem \
  --client-key=kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context system:kube-scheduler \
  --cluster=kubernetes \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context system:kube-scheduler --kubeconfig=kube-scheduler.kubeconfig

}

function RemovePem() {
  #保留.pem和ca文件删除其他文件
  cd /opt/kubernetes/ssl/
  ls |grep -v ca |grep -v pem |xargs -i rm {}
}