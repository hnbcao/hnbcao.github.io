#!/bin/bash

source /tmp/kube_install/node_init_containerd.sh
source /tmp/kube_install/node_init_enviroment.sh
source /tmp/kube_install/node_install_assembly.sh

KUBE_VERSION=$1
IMAGE_REPOSITORY=$2
IMAGE_REPOSITORY_ENDPOINT=$3
DOCKER_MIRROR=$4

# 1. 系统配置修改

echo "begin to initialization node"

initNodeEnviroment

echo "successed initialization node"

# 2. kubernetes相关组件安装

echo "begin to install assemblys on node"

installAssembly ${KUBE_VERSION}

echo "successed install assemblys on node"

# 3. 初始化Containerd配置

echo "begin to config containerd"

imageRepository=${IMAGE_REPOSITORY:-registry.aliyuncs.com/google_containers}
imageRepositoryEndpoint=${IMAGE_REPOSITORY_ENDPOINT:-https://registry.aliyuncs.com}
dockerMirror=${DOCKER_MIRROR:-https://registry-1.docker.io}

initContainerd imageRepository imageRepositoryEndpoint dockerMirror

echo "successed config containerd"