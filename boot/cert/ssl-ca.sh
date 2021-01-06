#!/usr/bin/env bash

# 下载生成证书工具
function DownLoadCFSSL(){
  sudo mkdir -p /opt/kubernetes/ssl && cd /opt/kubernetes/ssl
  wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
  wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
  wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64

  chmod +x cfssl*
  sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
  sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
  sudo mv cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo
  
  export PATH=/usr/local/bin:$PATH
}

#生成证书
function CreateCert-CA(){
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

function RemovePem() {
  #保留.pem文件删除其他文件
  ls |grep -v pem |xargs -i rm {}
}