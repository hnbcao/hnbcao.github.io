#!/bin/bash
IMAGE_REPOSITORY=${IMAGE_REPOSITORY:-registry.aliyuncs.com}
CONTROL_PLANE_ENDPOINT=${CONTROL_PLANE_ENDPOINT:-10.73.13.62:8443}
CIDR=${CIDR:-10.244.0.0/16}
SERVICE_SUBNET=${SERVICE_SUBNET:-10.96.0.0/12}
KUBE_VERSION=${KUBE_VERSION:-1.24.0}
CERT_SANS=${CERT_SANS:-master1.segma.local,master2.segma.local,master3.segma.local}
nodes=(${CONTROL_PLANE_NODE//,/ })

cat <<EOF > /tmp/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
---
apiServer:
  certSANs:
etcd:
  local:
    serverCertSANs:
    peerCertSANs:
apiVersion: kubeadm.k8s.io/v1beta2
clusterName: kubernetes
controlPlaneEndpoint: ${CONTROL_PLANE_ENDPOINT}
imageRepository: ${IMAGE_REPOSITORY}/google_containers
kind: ClusterConfiguration
kubernetesVersion: ${KUBE_VERSION}
networking:
  dnsDomain: kubernetes.local
  podSubnet: ${CIDR}
  serviceSubnet: ${SERVICE_SUBNET}
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clusterCIDR: ${CIDR}
kind: KubeProxyConfiguration
mode: ipvs
EOF

for node in ${nodes[@]}
do
  sed -i "/.*CertSANs:/a\    - $node" /tmp/kubeadm-config.yaml
  sed -i "/.*certSANs:/a\  - $node" /tmp/kubeadm-config.yaml
done

kubeadm init --config /tmp/kubeadm-config.yaml