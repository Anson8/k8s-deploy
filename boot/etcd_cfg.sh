#!/usr/bin/env bash
DEPLOY_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
## TODO 引入deployConfig配置文件
. $DEPLOY_PATH/../conf/clusterConfig

#生成etcd的配置文件
function CFG_ETCD(){
  cd /opt/kubernetes/cfg

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

}

