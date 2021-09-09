# kube-proxy报错 "--random-fully"解决方法
1. 现象
```
[localhost] kube-proxy: I0621 14:04:40.100452    5423 proxier.go:1815] Not using `--random-fully` in the MASQUERADE rule for iptables because the local version of iptables does not support i
```
2. 解决方法
```
## 安装升级iptables所需依赖:
yum install gcc make libnftnl-devel libmnl-devel autoconf automake libtool bison flex  \
libnetfilter_conntrack-devel libnetfilter_queue-devel libpcap-devel bzip2

## 编译安装iptables并覆盖现有iptables:
cd /data
wget wget https://www.netfilter.org/projects/iptables/files/iptables-1.6.2.tar.bz2
tar -xvf iptables-1.6.2.tar.bz2
cd iptables-1.6.2
./autogen.sh
./configure
make -j4
make install

## 重启kubelet和kube-proxy
systemctl restart  kube-proxy
systemctl restart kubelet
```

# kube-apiserver 无法启动
```
kube-apiserver: Error: invalid argument "DynamicAuditing=true" for "--feature-gates" flag: unrecognized feature gate: DynamicAuditing
```
- 原因：新版本不支持这两个参数
  ```
  --feature-gates=DynamicAuditing=true
  --audit-dynamic-configuration
  ```
 
# kube-scheduler 启动失败
```
no kind "KubeSchedulerConfiguration" is registered for version "kubescheduler.config.k8s.io/v1alpha1" in scheme "k8s.io/kubernetes/pkg/scheduler/apis/config/scheme/scheme.go:30"
```
- 原因:kube-scheduler.yaml配置变更
  ```
  cat >kube-scheduler0$n.yaml <<EOF
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
  ```