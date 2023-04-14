#!/usr/bin/env bash
DEPLOY_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")"
## TODO 引入deployConfig配置文件
. $DEPLOY_PATH/../conf/clusterConfig

function MASTER-CFG() {
  #生成etcd的配置文件
  echo "create etcd-cfg........................."
  ETCD-CFG
  #生成kube-apiserver的配置文件
  echo "create kube-apiserver-cfg........................."
  KUBE-APISERVER-CFG
  #生成kube-controller-manager的配置文件
  echo "create kube-controller-manager-cfg........................."
  KUBE-CONTROLLER-MANAGER-CFG
  #生成kube-scheduler的配置文件
  echo "create kube-scheduler-cfg........................."
  KUBE-SCHEDULER-CFG
  #生成kube-nginx配置文件
  echo "create kube-nginx-cfg........................."
  KUBE-NGINX-CFG
}

#生成etcd的配置文件
function ETCD-CFG() {
cd /opt/kubernetes/cfg 
cat > etcd01.service <<EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
Type=notify
WorkingDirectory=${ETCD_DATA_DIR}
ExecStart=/opt/kubernetes/bin/etcd \\
  --data-dir=${ETCD_DATA_DIR} \\
  --wal-dir=${ETCD_WAL_DIR} \\
  --name=etcd0${n} \\
  --cert-file=/opt/kubernetes/ssl/etcd.pem \\
  --key-file=/opt/kubernetes/ssl/etcd-key.pem \\
  --trusted-ca-file=/opt/kubernetes/ssl/ca.pem \\
  --peer-cert-file=/opt/kubernetes/ssl/etcd.pem \\
  --peer-key-file=/opt/kubernetes/ssl/etcd-key.pem \\
  --peer-trusted-ca-file=/opt/kubernetes/ssl/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --listen-peer-urls=https://${K8S_ETCD}:2380 \\
  --initial-advertise-peer-urls=https://${K8S_ETCD}:2380 \\
  --listen-client-urls=https://${K8S_ETCD}:2379,http://127.0.0.1:2379 \\
  --advertise-client-urls=https://${K8S_ETCD}:2379 \\
  --initial-cluster-token=etcd-cluster-0 \\
  --initial-cluster=${ETCD_INITIAL_CLUSTER} \\
  --initial-cluster-state=new \\
  --auto-compaction-mode=periodic \\
  --auto-compaction-retention=1 \\
  --max-request-bytes=33554432 \\
  --quota-backend-bytes=6442450944 \\
  --heartbeat-interval=250 \\
  --election-timeout=2000
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
  done


}

#生成kube-apiserver的配置文件
function KUBE-APISERVER-CFG() {
  mkdir -p /opt/kubernetes/cfg/kube-apiserver
  cd /opt/kubernetes/cfg/kube-apiserver

cat > kube-apiserver01.service <<EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
WorkingDirectory=${K8S_DIR}/kube-apiserver
ExecStart=/opt/kubernetes/bin/kube-apiserver \\
  --advertise-address=${K8S_MASTER} \\
  --default-not-ready-toleration-seconds=360 \\
  --default-unreachable-toleration-seconds=360 \\
  --max-mutating-requests-inflight=2000 \\
  --max-requests-inflight=4000 \\
  --default-watch-cache-size=200 \\
  --delete-collection-workers=2 \\
  --encryption-provider-config=/opt/kubernetes/cfg/encryption-config.yaml \\
  --etcd-cafile=/opt/kubernetes/ssl/ca.pem \\
  --etcd-certfile=/opt/kubernetes/ssl/kubernetes.pem \\
  --etcd-keyfile=/opt/kubernetes/ssl/kubernetes-key.pem \\
  --etcd-servers=${K8S_ETCD} \\
  --bind-address=${K8S_MASTER} \\
  --secure-port=6443 \\
  --tls-cert-file=/opt/kubernetes/ssl/kubernetes.pem \\
  --tls-private-key-file=/opt/kubernetes/ssl/kubernetes-key.pem \\
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

cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

  done  
}

#生成kube-controller-manager的配置文件
function KUBE-CONTROLLER-MANAGER-CFG() {
  mkdir -p /opt/kubernetes/cfg/kube-controller-manager
  cd /opt/kubernetes/cfg/kube-controller-manager

cat > kube-controller-manager01.service <<EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
WorkingDirectory=${K8S_DIR}/kube-controller-manager
ExecStart=/opt/kubernetes/bin/kube-controller-manager \\
  --profiling \\
  --cluster-name=kubernetes \\
  --controllers=*,bootstrapsigner,tokencleaner \\
  --kube-api-qps=1000 \\
  --kube-api-burst=2000 \\
  --leader-elect \\
  --use-service-account-credentials\\
  --concurrent-service-syncs=2 \\
  --bind-address=${K8S_MASTER}\\
  --secure-port=10252 \\
  --tls-cert-file=/opt/kubernetes/ssl/kube-controller-manager.pem \\
  --tls-private-key-file=/opt/kubernetes/ssl/kube-controller-manager-key.pem \\
  --port=0 \\
  --authentication-kubeconfig=/opt/kubernetes/cfg/kube-controller-manager.kubeconfig \\
  --client-ca-file=/opt/kubernetes/ssl/ca.pem \\
  --requestheader-client-ca-file=/opt/kubernetes/ssl/ca.pem \\
  --requestheader-extra-headers-prefix="X-Remote-Extra-" \\
  --requestheader-group-headers=X-Remote-Group \\
  --requestheader-username-headers=X-Remote-User \\
  --authorization-kubeconfig=/opt/kubernetes/cfg/kube-controller-manager.kubeconfig \\
  --cluster-signing-cert-file=/opt/kubernetes/ssl/ca.pem \\
  --cluster-signing-key-file=/opt/kubernetes/ssl/ca-key.pem \\
  --experimental-cluster-signing-duration=876000h \\
  --horizontal-pod-autoscaler-sync-period=10s \\
  --concurrent-deployment-syncs=10 \\
  --concurrent-gc-syncs=30 \\
  --node-cidr-mask-size=24 \\
  --service-cluster-ip-range=${SERVICE_CIDR} \\
  --pod-eviction-timeout=6m \\
  --terminated-pod-gc-threshold=10000 \\
  --root-ca-file=/opt/kubernetes/ssl/ca.pem \\
  --service-account-private-key-file=/opt/kubernetes/ssl/ca-key.pem \\
  --kubeconfig=/opt/kubernetes/cfg/kube-controller-manager.kubeconfig \\
  --logtostderr=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

  done  
}

#生成kube-scheduler的配置文件
function KUBE-SCHEDULER-CFG() {
  mkdir -p /opt/kubernetes/cfg/kube-scheduler
  cd /opt/kubernetes/cfg/kube-scheduler

cat > kube-scheduler01.service <<EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
WorkingDirectory=${K8S_DIR}/kube-scheduler
ExecStart=/opt/kubernetes/bin/kube-scheduler \\
  --config=/opt/kubernetes/cfg/kube-scheduler.yaml \\
  --bind-address=${K8S_MASTER} \\
  --secure-port=10259 \\
  --port=0 \\
  --tls-cert-file=/opt/kubernetes/ssl/kube-scheduler.pem \\
  --tls-private-key-file=/opt/kubernetes/ssl/kube-scheduler-key.pem \\
  --authentication-kubeconfig=/opt/kubernetes/cfg/kube-scheduler.kubeconfig \\
  --client-ca-file=/opt/kubernetes/ssl/ca.pem \\
  --requestheader-client-ca-file=/opt/kubernetes/ssl/ca.pem \\
  --requestheader-extra-headers-prefix="X-Remote-Extra-" \\
  --requestheader-group-headers=X-Remote-Group \\
  --requestheader-username-headers=X-Remote-User \\
  --authorization-kubeconfig=/opt/kubernetes/cfg/kube-scheduler.kubeconfig \\
  --logtostderr=true \\
  --v=2
Restart=always
RestartSec=5
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOF
cat >kube-scheduler01.yaml <<EOF
apiVersion: kubescheduler.config.k8s.io/v1beta1
kind: KubeSchedulerConfiguration
clientConnection:
  burst: 200
  kubeconfig: "/opt/kubernetes/cfg/kube-scheduler.kubeconfig"
  qps: 100
enableContentionProfiling: false
enableProfiling: true
leaderElection:
  leaderElect: true
EOF

  done  
}

#生成kube-nginx配置文件
function KUBE-NGINX-CFG() {
  cd /opt/kubernetes/cfg

  cat > kube-nginx.conf <<EOF
worker_processes 1;

events {
    worker_connections  1024;
}

stream {
    upstream backend {
        hash $remote_addr consistent;
        server ${K8S_MASTER}:6443  max_fails=3 fail_timeout=30s;
    }

    server {
        listen 127.0.0.1:8443;
        proxy_connect_timeout 1s;
        proxy_pass backend;
    }
}
EOF
  cat > kube-nginx.service <<EOF
[Unit]
Description=kube-apiserver nginx proxy
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
ExecStartPre=/opt/kubernetes/bin/kube-nginx -c /opt/kubernetes/cfg/kube-nginx.conf -p /opt/kubernetes/kube-nginx -t
ExecStart=/opt/kubernetes/bin/kube-nginx -c /opt/kubernetes/cfg/kube-nginx.conf -p /opt/kubernetes/kube-nginx
ExecReload=/opt/kubernetes/bin/kube-nginx -c /opt/kubernetes/cfg/kube-nginx.conf -p /opt/kubernetes/kube-nginx -s reload
PrivateTmp=true
Restart=always
RestartSec=5
StartLimitInterval=0
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

}