#!/usr/bin/env bash
DEPLOY_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
## TODO 引入deployConfig配置文件
. $DEPLOY_PATH/../conf/clusterConfig

#生成配置文件
function KUBECFG(){
  KUBE-CONF
  KUBE-APISERVER
  KUBELET-CONF
  KUBE-PROXY

}

function KUBE-CONF(){
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
ETCD_WAL_DIR="$ETCD_WAL_DIR"
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

#生成kubelet的配置文件
function KUBELET-CONF(){
  mkdir -p /opt/kubernetes/cfg/kubelet
  cd /opt/kubernetes/cfg/kubelet

  let len=${#K8S_SLAVES[*]}
  for ((i=0; i<$len; i++))
  do
      let n=$i+1
      node_name=slave"0"$n
      # 创建 token
        export BOOTSTRAP_TOKEN=$(kubeadm token create \
              --description kubelet-bootstrap-token \
              --groups system:bootstrappers:${node_name} \
              --kubeconfig ~/.kube/config)

      # 设置集群参数
        kubectl config set-cluster kubernetes \
          --certificate-authority=/opt/kubernetes/ssl/ca.pem \
          --embed-certs=true \
          --server=${KUBE_APISERVER} \
          --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig

      # 设置客户端认证参数
        kubectl config set-credentials kubelet-bootstrap \
          --token=${BOOTSTRAP_TOKEN} \
          --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig

      # 设置上下文参数
        kubectl config set-context default \
          --cluster=kubernetes \
          --user=kubelet-bootstrap \
          --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig

      # 设置默认上下文
        kubectl config use-context default --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig

cat > kubelet-config-$n.yaml <<EOF
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: "##NODE_IP##"
staticPodPath: ""
syncFrequency: 1m
fileCheckFrequency: 20s
httpCheckFrequency: 20s
staticPodURL: ""
port: 10250
readOnlyPort: 0
rotateCertificates: true
serverTLSBootstrap: true
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/opt/kubernetes/ssl/ca.pem"
authorization:
  mode: Webhook
registryPullQPS: 0
registryBurst: 20
eventRecordQPS: 0
eventBurst: 20
enableDebuggingHandlers: true
enableContentionProfiling: true
healthzPort: 10248
healthzBindAddress: "${K8S_SLAVES[i]}"
clusterDomain: "${CLUSTER_DNS_DOMAIN}"
clusterDNS:
  - "${CLUSTER_DNS_SVC_IP}"
nodeStatusUpdateFrequency: 10s
nodeStatusReportFrequency: 1m
imageMinimumGCAge: 2m
imageGCHighThresholdPercent: 85
imageGCLowThresholdPercent: 80
volumeStatsAggPeriod: 1m
kubeletCgroups: ""
systemCgroups: ""
cgroupRoot: ""
cgroupsPerQOS: true
cgroupDriver: cgroupfs
runtimeRequestTimeout: 10m
hairpinMode: promiscuous-bridge
maxPods: 220
podCIDR: "${CLUSTER_CIDR}"
podPidsLimit: -1
resolvConf: /etc/resolv.conf
maxOpenFiles: 1000000
kubeAPIQPS: 1000
kubeAPIBurst: 2000
serializeImagePulls: false
evictionHard:
  memory.available:  "100Mi"
nodefs.available:  "10%"
nodefs.inodesFree: "5%"
imagefs.available: "15%"
evictionSoft: {}
enableControllerAttachDetach: true
failSwapOn: true
containerLogMaxSize: 20Mi
containerLogMaxFiles: 10
systemReserved: {}
kubeReserved: {}
systemReservedCgroup: ""
kubeReservedCgroup: ""
enforceNodeAllocatable: ["pods"]
EOF

cat > kubelet-$n.service <<EOF
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=${K8S_DIR}/kubelet
ExecStart=/opt/kubernetes/bin/kubelet \\
  --hostname-override=${K8S_SLAVES[i]} \\
  --pod-infra-container-image=registry.cn-beijing.aliyuncs.com/images_k8s/pause-amd64:3.1 \\
  --bootstrap-kubeconfig=/opt/kubernetes/kubelet-bootstrap.kubeconfig \\
  --kubeconfig=/opt/kubernetes/cfg/kubelet.kubeconfig \\
  --config=/opt/kubernetes/cfg/kubelet-config.yaml \\
  --cert-dir=/opt/kubernetes/ssl \\
  --logtostderr=true \\
  --v=2

[Install]
WantedBy=multi-user.target
EOF

#kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --group=system:bootstrappers

  done
}

#生成kubelet的配置文件
function KUBE-PROXY(){
cd /opt/kubernetes/ssl
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

mkdir -p /opt/kubernetes/cfg/kube-proxy
cd /opt/kubernetes/cfg/kube-proxy

kubectl config set-cluster kubernetes \
  --certificate-authority=/opt/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials kube-proxy \
  --client-certificate=/opt/kubernetes/ssl/kube-proxy.pem \
  --client-key=/opt/kubernetes/ssl/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig


  let len=${#K8S_SLAVES[*]}
  for ((i=0; i<$len; i++))
  do
      let n=$i+1
      node_name=slave"0"$n
  cat > kube-proxy-config-0$n.yaml <<EOF
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  burst: 200
  kubeconfig: "/opt/kubernetes/cfg/kube-proxy.kubeconfig"
  qps: 100
bindAddress: ${K8S_SLAVES[i]}
healthzBindAddress: ${K8S_SLAVES[i]}:10256
metricsBindAddress: ${K8S_SLAVES[i]}:10249
enableProfiling: true
clusterCIDR: ${CLUSTER_CIDR}
hostnameOverride: ${node_name}
mode: "ipvs"
portRange: ""
kubeProxyIPTablesConfiguration:
  masqueradeAll: false
kubeProxyIPVSConfiguration:
  scheduler: rr
  excludeCIDRs: []
EOF
  done

  #生成kube-proxy.service
  cat > kube-proxy.service <<EOF
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
WorkingDirectory=${K8S_DIR}/kube-proxy
ExecStart=/opt/kubernetes/bin/kube-proxy \\
  --config=/opt/kubernetes/cfg/kube-proxy-config.yaml \\
  --logtostderr=true \\
  --v=2
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
}

#生成kube-apiserver的配置文件
function KUBE-APISERVER() {
  mkdir -p /opt/kubernetes/cfg/kube-apiserver
  cd /opt/kubernetes/cfg/kube-apiserver
  let len=${#K8S_MASTER[*]}
  for ((i=0; i<$len; i++))
  do
    let n=$i+1
    cat > kube-apiserver0$n.service <<EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
WorkingDirectory=${K8S_DIR}/kube-apiserver
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${K8S_MASTER[i]} \\
  --default-not-ready-toleration-seconds=360 \\
  --default-unreachable-toleration-seconds=360 \\
  --feature-gates=DynamicAuditing=true \\
  --max-mutating-requests-inflight=2000 \\
  --max-requests-inflight=4000 \\
  --default-watch-cache-size=200 \\
  --delete-collection-workers=2 \\
  --encryption-provider-config=/opt/kubernetes/cfg/encryption-config.yaml \\
  --etcd-cafile=/opt/kubernetes/ssl/ca.pem \\
  --etcd-certfile=/opt/kubernetes/ssl/kubernetes.pem \\
  --etcd-keyfile=/opt/kubernetes/ssl/kubernetes-key.pem \\
  --etcd-servers=${ETCD_ENDPOINTS} \\
  --bind-address=${K8S_MASTER[i]} \\
  --secure-port=6443 \\
  --tls-cert-file=/opt/kubernetes/ssl/kubernetes.pem \\
  --tls-private-key-file=/opt/kubernetes/ssl/kubernetes-key.pem \\
  --insecure-port=0 \\
  --audit-dynamic-configuration \\
  --audit-log-maxage=15 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-truncate-enabled \\
  --audit-log-path=${K8S_DIR}/kube-apiserver/audit.log \\
  --audit-policy-file=/opt/kubernetes/cfg/audit-policy.yaml \\
  --profiling \\
  --anonymous-auth=false \\
  --client-ca-file=/opt/kubernetes/ssl/ca.pem \\
  --enable-bootstrap-token-auth \\
  --requestheader-allowed-names="aggregator" \\
  --requestheader-client-ca-file=/opt/kubernetes/ssl/ca.pem \\
  --requestheader-extra-headers-prefix="X-Remote-Extra-" \\
  --requestheader-group-headers=X-Remote-Group \\
  --requestheader-username-headers=X-Remote-User \\
  --service-account-key-file=/opt/kubernetes/ssl/ca.pem \\
  --authorization-mode=Node,RBAC \\
  --runtime-config=api/all=true \\
  --enable-admission-plugins=NodeRestriction \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --event-ttl=168h \\
  --kubelet-certificate-authority=/opt/kubernetes/ssl/ca.pem \\
  --kubelet-client-certificate=/opt/kubernetes/ssl/kubernetes.pem \\
  --kubelet-client-key=/opt/kubernetes/ssl/kubernetes-key.pem \\
  --kubelet-https=true \\
  --kubelet-timeout=10s \\
  --proxy-client-cert-file=/opt/kubernetes/ssl/proxy-client.pem \\
  --proxy-client-key-file=/opt/kubernetes/ssl/proxy-client-key.pem \\
  --service-cluster-ip-range=${SERVICE_CIDR} \\
  --service-node-port-range=${NODE_PORT_RANGE} \\
  --logtostderr=true \\
  --v=2
Restart=on-failure
RestartSec=10
Type=notify
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
  done  
}