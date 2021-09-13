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

# 证书服务加入
```
no kind "CertificateSigningRequest" is registered for version "certificates.k8s.io/v1" in scheme "k8s.io/kubernetes/pkg/kubectl/scheme/scheme.go:28"
```  
- 原因：kubectl版本于服务版本不一致，需替换