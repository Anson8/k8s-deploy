#!/usr/bin/env bash
DEPLOY_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
## TODO 引入deployConfig配置文件
. $DEPLOY_PATH/../conf/clusterConfig

function KUBECTL-MASTER-CFG() {
  #生成master-kube-proxy配置文件
  echo "create master-kube-proxy-cfg........................."
  KUBE-PROXY-MASTER-CFG
  #生成master-kubelet配置文件
  echo "create master-kubelet-cfg........................."
  KUBELET-MASTER-CFG
}

#生成kube-proxy的配置文件
function KUBE-PROXY-MASTER-CFG() {
  mkdir -p /opt/kubernetes/cfg/kube-proxy
  cd /opt/kubernetes/cfg/kube-proxy
  let len=${#K8S_MASTER[*]}
  for ((i=0; i<$len; i++))
  do
    let n=$i+1
    node_name=k8s-master0$n
cat > kube-proxy-config-$node_name.yaml <<EOF
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  burst: 200
  kubeconfig: "/opt/kubernetes/cfg/kube-proxy.kubeconfig"
  qps: 100
bindAddress: ${K8S_MASTER[i]}
healthzBindAddress: ${K8S_MASTER[i]}:10256
metricsBindAddress: ${K8S_MASTER[i]}:10249
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
}


#生成kubelet的配置文件
function KUBELET-MASTER-CFG(){
  mkdir -p /opt/kubernetes/cfg/kubelet
  cd /opt/kubernetes/cfg/kubelet
  let len=${#K8S_MASTER[*]}
  for ((i=0; i<$len; i++))
  do
      let n=$i+1
      node_name=k8s-master0$n
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


cat > kubelet-config-$node_name.yaml <<EOF
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: ${K8S_MASTER[i]}
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
healthzBindAddress: ${K8S_MASTER[i]}
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
cgroupDriver: systemd
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

cat > kubelet-$node_name.service <<EOF
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
