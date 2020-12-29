# k8s-deploy

# 部署etcd（3台）

# 部署Master
  ## 复制二进制程序
  ## 创建证书
  ## 部署kube-apiserver服务
  ## 部署kube-Controller服务
  ## 配置kube-scheduler服务
  ## 配置flanneld服务
  ## 启动服务
  - daemon-reload 
  - kube-apiserver 
  - kube-controller-manager 
  - kube-scheduler 
  - flanneld
  ## 修改docker服务

# 部署node节点
  ## 复制程序文件
  ## 配置Flanned以及修改Docker服务
  ## 配置kubelet服务
  ## 配置kube-proxy服务

# 部署附件组件
  ## 部署DNS
  ## 部署Dashboard



# 修改配置
  1. docker的daemon文件（路径：k8s-deploy/boot/genconf/daemon.json）

