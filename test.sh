#!/usr/bin/env bash
  K8S_ETCD=(192.168.10.5 192.168.10.6 192.168.10.7)
  ETCD_DATA_DIR="/data/k8s/etcd/data"
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
    cat > etcd0$n.json <<EOF
    #[Member]
    ETCD_NAME="etcd0$n"
    ETCD_DATA_DIR="$ETCD_DATA_DIR"
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

