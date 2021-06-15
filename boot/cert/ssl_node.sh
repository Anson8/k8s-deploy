#!/usr/bin/env bash
DEPLOY_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
CONF_PATH=$DEPLOY_PATH/../../conf/clusterConfig

#生成Node节点证书
function SSL-NODE() {
  cd /opt/kubernetes/ssl
  #生成flannel证书
  FLANNEL-SSL
  #生成kube-proxy证书
  KUBE-PROXY-SSL  
}  
#生成Flannel证书，修改host node节点集群IP
function FLANNEL-SSL(){
  cat > flanneld-csr.json <<EOF
  {
    "CN": "flanneld",
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
    -profile=kubernetes flanneld-csr.json | cfssljson -bare flanneld
}

#生成kube-proxy证书
function KUBE-PROXY-SSL(){
cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
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
  -profile=kubernetes  kube-proxy-csr.json | cfssljson -bare kube-proxy
}