
#!/usr/bin/env bash
DEPLOY_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
## TODO 引入deployConfig配置文件
. $DEPLOY_PATH/../conf/clusterConfig

function NODE-CFG() {
  #生成kubelet的配置文件
  KUBELET-CFG
  #生成kube-proxy的配置文件
  KUBE-PROXY-CFG
  #生成flanneld配置文件  
  FLANNELD-CFG

}

#生成kubelet的配置文件
function KUBELET-CFG(){
  mkdir -p /opt/kubernetes/cfg/kubelet  
  cd /opt/kubernetes/cfg/kubelet
  let len=${#K8S_SLAVES[*]}
  for ((i=0; i<$len; i++))
  do
      let n=$i+1
      node_name=slave0$n
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


cat > kubelet-config0$n.yaml <<EOF
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: ${K8S_SLAVES[i]}
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
healthzBindAddress: ${K8S_SLAVES[i]}
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

cat > kubelet0$n.service <<EOF
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=${K8S_DIR}/kubelet
ExecStart=/opt/kubernetes/bin/kubelet \\
  --hostname-override=${node_name} \\
  --pod-infra-container-image=registry.cn-shenzhen.aliyuncs.com/4d_prom/pause-amd64:3.1 \\
  --bootstrap-kubeconfig=/opt/kubernetes/cfg/kubelet-bootstrap.kubeconfig \\
  --kubeconfig=/opt/kubernetes/cfg/kubelet.kubeconfig \\
  --config=/opt/kubernetes/cfg/kubelet-config.yaml \\
  --cert-dir=/opt/kubernetes/ssl \\
  --logtostderr=true \\
  --v=2

[Install]
WantedBy=multi-user.target
EOF
  done
}

#生成kube-proxy的配置文件
function KUBE-PROXY-CFG(){
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
      node_name=slave0$n
  cat > kube-proxy-config0$n.yaml <<EOF
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

#生成flanneld配置文件
function FLANNELD-CFG(){
cd /opt/kubernetes/cfg 
  ETCD_SERVERS=
  let len=${#K8S_ETCD[*]}
  for ((i=0; i<$len; i++))
  do
      let n=$i+1
      if [ "$len" -ne "$n" ]; then
       ETCD_SERVERS+="https://${K8S_ETCD[i]}:2379",
       continue
      fi
      ETCD_SERVERS+="https://${K8S_ETCD[i]}:2379"
      echo "K8S_ETCD"==[${ETCD_SERVERS}]
  done 

cat > flanneld.service << EOF
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
After=network-online.target
Wants=network-online.target
After=etcd.service
Before=docker.service

[Service]
Type=notify
ExecStart=/opt/kubernetes/bin/flanneld \\
  -etcd-cafile=/opt/kubernetes/ssl/ca.pem \\
  -etcd-certfile=/opt/kubernetes/ssl/flanneld.pem \\
  -etcd-keyfile=/opt/kubernetes/ssl/flanneld-key.pem \\
  -etcd-endpoints=${ETCD_SERVERS} \\
  -etcd-prefix=${FLANNEL_ETCD_PREFIX} \\
  -iface=${IFACE} \\
  -ip-masq
ExecStartPost=/opt/kubernetes/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker
Restart=always
RestartSec=5
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
RequiredBy=docker.service
EOF
}