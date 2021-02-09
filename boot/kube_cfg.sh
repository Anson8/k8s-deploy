#!/usr/bin/env bash
DEPLOY_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
## TODO 引入deployConfig配置文件
. $DEPLOY_PATH/../conf/clusterConfig

#生成配置文件
function KUBECFG(){
  cd /opt/kubernetes/cfg

#生成etcd的配置文件
  ETCD_INITIAL_CLUSTER=
  let len=${#K8S_ETCD[*]}
  for ((i=0; i<$len; i++))
  do
      let n=$i+1
      if [ "$len" -ne "$n" ]; then
       ETCD_INITIAL_CLUSTER+="etcd0$n=https://${K8S_ETCD[i]}:2380",
       continue
      fi
      ETCD_INITIAL_CLUSTER+="etcd0$n=https://${K8S_ETCD[i]}:2380"
      echo "K8S_ETCD"==[${ETCD_INITIAL_CLUSTER}]
  done  

  for ((i=0; i<$len; i++))
  do
    let n=$i+1
    cat > etcd0$n <<EOF
#[Member]
ETCD_NAME="etcd0$n"
ETCD_DATA_DIR="$ETCD_DATA_DIR"
ETCD_WAL_DIR="$ETCD_DATA_DIR"
ETCD_LISTEN_PEER_URLS="https://${K8S_ETCD[i]}:2380"
ETCD_LISTEN_CLIENT_URLS="https://${K8S_ETCD[i]}:2379"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://${K8S_ETCD[i]}:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://${K8S_ETCD[i]}:2379"
ETCD_INITIAL_CLUSTER="$ETCD_INITIAL_CLUSTER"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF
  done

#生成flanneld配置文件
  cat > flannel <<EOF
#[Clustering]
ETCD_ENDPOINTS="${ETCD_ENDPOINTS}"
FLANNEL_ETCD_PREFIX="${FLANNEL_ETCD_PREFIX}"
EOF

#生成kube-nginx配置文件
  nodes=${K8S_MASTER[@]}
  SERVER_CLUSTER=
  for ip in $nodes;
  do
    SERVER_CLUSTER+="server ${ip}:6443  max_fails=3 fail_timeout=30s;"
  done

  cat > kube-nginx.conf <<EOF
worker_processes 1;

events {
    worker_connections  1024;
}

stream {
    upstream backend {
        hash $remote_addr consistent;
        ${SERVER_CLUSTER}
    }

    server {
        listen 127.0.0.1:8443;
        proxy_connect_timeout 1s;
        proxy_pass backend;
    }
}
EOF

#生成kubecfg-master配置文件
  cat > kubecfg-master <<EOF
#[Clustering]
K8S_DIR="${K8S_DIR}"
ETCD_ENDPOINTS="${ETCD_ENDPOINTS}"
SERVICE_CIDR="${SERVICE_CIDR}"
NODE_PORT_RANGE="${NODE_PORT_RANGE}"
EOF

}
