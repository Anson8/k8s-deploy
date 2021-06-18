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


# DEV环境部署
 1. 修改clusterConfig中的变量（ENV、K8S_ETCD：[192.168.21.2 192.168.21.3 192.168.21.4]、K8S_SLAVES、HOST_NAMES）
 2. 配置/etc/hosts
   ```
    192.168.19.31   dev-glusterfs1
    192.168.19.32   dev-glusterfs2
    192.168.19.33   dev-glusterfs3
    192.168.19.34   dev-glusterfs4
   ```
 3. 安装glusterfs客户端，用于挂载logs目录
   ```
    sudo mkdir /logs
    sudo yum -y install wget fuse fuse-libs
    sudo yum install glusterfs-* -y
   ```

# 二进制包
https://sdtc-public.oss-cn-shenzhen.aliyuncs.com/deployment/k8s-data.zip