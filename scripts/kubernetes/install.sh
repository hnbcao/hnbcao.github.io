#!/bin/bash

RED='\E[1;31m'       # 红
GREEN='\E[1;32m'    # 绿
YELOW='\E[1;33m'    # 黄
BLUE='\E[1;34m'     # 蓝
PINK='\E[1;35m'     # 粉红
RES='\E[0m'          # 清除颜色
BASE_DIR=$(pwd)
# 获取数据文件名（Get data file name）
source ${BASE_DIR}/env.sh

KUBE_VERSION=${KUBE_VERSION:-v1.24.0}
IMAGE_REPOSITORY=${IMAGE_REPOSITORY:-registry.aliyuncs.com/google_containers}
IMAGE_REPOSITORY_ENDPOINT=${IMAGE_REPOSITORY_ENDPOINT:-https://registry.aliyuncs.com}
DOCKER_MIRROR=${DOCKER_MIRROR:-https://registry-1.docker.io}
CONTROL_PLANE_ENDPOINT=${CONTROL_PLANE_ENDPOINT:-10.73.13.62:8443}
CIDR=${CIDR:-10.244.0.0/16}
SERVICE_SUBNET=${SERVICE_SUBNET:-10.96.0.0/12}
CONTROL_PLANE_NODE=${CONTROL_PLANE_NODE:-master1.segma.local,master2.segma.local,master3.segma.local}

filename=$1

# 检测是否安装expect
if [[ ! -e /usr/bin/expect ]]; then
  echo "Install expect"
  yum -y install expect
fi

# 生成秘钥文件(Generate a key file for node)
if [[ ! -e /root/.ssh/id_rsa ]]; then 
  echo "Generate id_rsa"
  ssh-keygen -t rsa -P '' -f /root/.ssh/id_rsa
fi

# 配置当前节点对其余节点的免密登陆

echo -e "${GREEN}1. 配置当前节点对其余节点的免密登陆${RES}"
cat ${filename} | while read ip host short passwd; do
  sed -i "/${ip}.*/d" /etc/hosts
  echo ${ip} ${host} ${short} >> /etc/hosts
  expect << EOF
    set timeout -1
    spawn ssh-copy-id -i /root/.ssh/id_rsa.pub ${ip}
    expect {
    "yes/no" {send "yes\r"; exp_continue}
    "password" {send "${passwd}\r"}
    }
    expect eof
EOF
done

echo -e "${GREEN}2. 拷贝初始化脚本至节点${RES}"
cat ${filename} | while read ip host short passwd; do
  echo -e "${YELOW}2.1 脚本拷贝至节点:${short}${RES}"
  expect << EOF
    set timeout -1
    spawn ssh root@${ip} mkdir -p /tmp/kube_install/ 
    expect eof
EOF
  scp ${BASE_DIR}/node/*.sh root@${ip}:/tmp/kube_install/
done

echo -e "${GREEN}3. 节点初始化${RES}"
cat ${filename} | while read ip host short passwd; do
  echo -e "${YELOW}3.1 初始化节点:${short}${RES}"
  expect << EOF
    set timeout -1
    spawn ssh root@${ip} sh /tmp/kube_install/init_node.sh ${KUBE_VERSION} ${IMAGE_REPOSITORY} ${IMAGE_REPOSITORY_ENDPOINT} ${DOCKER_MIRROR}
    expect eof
EOF
done

echo -e "${GREEN}所有节点初始化完成${RES}"

sh ${BASE_DIR}/install_kubernetes.sh