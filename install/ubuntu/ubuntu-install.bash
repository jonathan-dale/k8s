#!/bin/bash

set -ou pipefail
## -e exits immediately on failure
## -o pipefail exits when any command in a pipe of commands returns non zero exit code not just the last command
## -u treat unset varables as errors and exit
## -x print each command before executing

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


function info {
        NOW=`date +%M%S`
        DIFF=`expr $NOW - $START_TIME`
	echo '[INFO]['$DIFF'] ' "$@"
}


START_TIME=`date +%M%S`

# trap errors for debugging ***NOTE: will not work with `set -e` option***
trap abort ERR


info "checking if user is root"
AMIROOT=`id -u`
[[ "$AMIROOT" == 0 ]] || die "must be root to run this..." 2

info "installing required packages (apt-transport-https, ca-certificates, curl, software-properties-common, gnupg2)"
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2


info "instaling containerd runtime"
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
## *** Find the correct ubuntu distro with $(lsb_release -cs) (e.g. focal, bionic...)
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


info "installing kubernetes packages"
# add K8's GPG key and repo
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
  
info "update and install bins, locking in at version 1.19.x.xx here so we can do an update later"
sudo apt-get update
sudo apt-get install -y kubelet=1.19.0-00 kubeadm=1.19.0-00 kubectl=1.19.0-00
sudo apt-mark hold kubelet kubeadm kubectl

# Use completion and 'k' simlink
ln -s /usr/local/bin/kubectl /usr/local/bin/k
echo 'source /usr/share/bash-completion/bash_completion' >> /home/ubuntu/.bashrc
echo 'source <(kubectl completion bash)' >> /home/ubuntu/.bashrc
echo 'complete -F __start_kubectl k' >> /home/ubuntu/.bashrc

# add ip tables and enable immediately
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

cat <<EOF

     Awesome!
     finished installing.......

     If this is a  master node, initialize cluster and add a CNI network overlay

          sudo kubeadm init --pod-network-cidr=10.244.0.0/16
          mkdir -p $HOME/.kube
          sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
          sudo chown $(id -u):$(id -g) $HOME/.kube/config
          kubectl apply -f https://docs.projectcalico.org/v3.14/manifests/calico.yaml

          #  install K9s
          sudo snap install k9s


EOF
