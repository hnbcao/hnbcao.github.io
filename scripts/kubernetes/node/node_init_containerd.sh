#!/bin/bash

function initContainerd() {
    imageRepository=$1
    imageRepositoryEndpoint=$2
    dockerMirror=$3
    cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
    containerd config default > /etc/containerd/config.toml
    sed -i "s#k8s.gcr.io/pause:#${imageRepository}/google_containers/pause:#g" /etc/containerd/config.toml
    sed -i "s#https://registry-1.docker.io#${dockerMirror}#g" /etc/containerd/config.toml
    sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
    sed -i "/.*plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors]/a\        [plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"${imageRepository}\"]" /etc/containerd/config.toml
    sed -i "/.*plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"${imageRepository}\"]/a\          endpoint = [\"${imageRepositoryEndpoint}\"]" /etc/containerd/config.toml
    sed -i "/.*plugins.\"io.containerd.grpc.v1.cri\".registry.configs]/a\        [plugins.\"io.containerd.grpc.v1.cri\".registry.configs.\"${imageRepository}\".tls]" /etc/containerd/config.toml
    sed -i "/.*plugins.\"io.containerd.grpc.v1.cri\".registry.configs.\"${imageRepository}\".tls]/a\          insecure_skip_verify = true" /etc/containerd/config.toml
}
