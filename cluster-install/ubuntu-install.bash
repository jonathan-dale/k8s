#!/bin/bash

function abort {
  EXIT_VAL="$?"
  echo "ABORT ERROR: $EXIT_VAL occurred, failed to execute '$BASH_COMMAND' line ${BASH_LINENO[0]}"
  exit "$EXIT_VAL"
}


function die {
  MESS="$1"
  EXIT_VAL="${2:-1}"
  echo 1>&2 "$MESS"
  exit "$EXIT_VAL"
}


AMIROOT=`id -u`

[[ "$AMIROOT" == 0 ]] || die "must be root to run this..." 2

# install junk
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2


function install_containerd {
  cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
  overlay
  br_netfilter
EOF
  
  sudo modprobe overlay
  sudo modprobe br_netfilter
  
  # Setup required sysctl params, these persist across reboots.
  cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
  net.bridge.bridge-nf-call-iptables  = 1
  net.ipv4.ip_forward                 = 1
  net.bridge.bridge-nf-call-ip6tables = 1
EOF
  
  # Apply sysctl params without reboot
  sudo sysctl --system


  ## Add Docker's official GPG key
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key --keyring /etc/apt/trusted.gpg.d/docker.gpg add -
  
  ## Add Docker apt repository.
  sudo add-apt-repository \
      "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) \
      stable"
  
  ## Install containerd
  sudo apt-get update && sudo apt-get install -y containerd.io

  # Configure containerd
  sudo mkdir -p /etc/containerd
  sudo containerd config default | sudo tee /etc/containerd/config.toml
  
  # Restart containerd
  sudo systemctl restart containerd
} 



function install_kubernetes {
  # add K8's GPG key
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  
  # add K8's repo
  cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
  deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
  
  # update and install bins *** Check correct ubuntu distro (focal, bionic...)
  ## we use version 1.19.x.xx here so we can do an update later,
  ## change this if you want newer versions
  sudo apt-get update
  sudo apt-get install -y kubelet=1.19.0-00 kubeadm=1.19.0-00 kubectl=1.19.0-00
  sudo apt-mark hold kubelet kubeadm kubectl
  
  # add ip tables and enable immediately
  echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf
  sudo sysctl -p
}
  

install_containerd
install_kubernetes

# awesome!
cat <<EOF

     Awesome!
     finished installing.......

     ### If this is a  master node, initialize cluster and add a CNI network overlay
     ### with these commands:

     $ sudo kubeadm init --pod-network-cidr=10.244.0.0/16
     $ kubectl apply -f https://docs.projectcalico.org/v3.14/manifests/calico.yaml


EOF
