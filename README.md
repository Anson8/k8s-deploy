# k8s-deploy
# ansible服务器
  - 创建admin用户并授权root权限
  - 创建 目录 存储 二进制文件sudo mkdir -p /opt/kubernetes/{bin,cfg,ssl} && sudo chown -R admin:admin /opt/kubernetes
  - 在/opt/kubernetes/bin中下载二进制文件
# 环境初始化
  - 将预安装ip加入known_hosts
  - 创建admin用户（授权sudo权限）
  - 部署公钥登陆
  - 格式化并挂在磁盘
  - 初始化k8s安装环境
  - 安装docker
# 生成证书
  - 根证书
  - etcd证书
  - apiserver证书
  - flannel证书
  - kube-proxy证书
  - kube-admin

# 部署Master
  - 部署etcd
  - 部署kube-apiserver
  - 部署kube-scheduler
  - 部署kube-controller-manager
  - 部署kube-nginx
# 部署Node节点
  - 部署kube-nginx
  - 部署kube-proxy
  - 部署kubelet
  - 部署flanneld


# 修改配置
  1. docker的daemon文件（路径：k8s-deploy/boot/genconf/daemon.json）




etcd
etcdctl
helm
kubeadm
kube-apiserver
kube-controller-manager
kubectl
kubelet
kube-scheduler

sudo mv docker-compose /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
sudo usermod -a -G docker admin
sudo systemctl restart docker

ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo 'Asia/Shanghai' > /etc/timezone

# 二进制包
https://sdtc-public.oss-cn-shenzhen.aliyuncs.com/deployment/k8s-data.zip