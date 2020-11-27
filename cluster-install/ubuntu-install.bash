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

# get GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# add docker repo
sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# add K8's GPG key
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# add K8's repo
cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

# update and install bins *** Check correct ubuntu distro (focal, bionic...)
## we use version 1.17.x.xx here so we can do an update later,
## change this if you want newer versions
sudo apt-get update
sudo apt-get install -y docker-ce=5:19.03.12~3-0~ubuntu-focal kubelet=1.17.8-00 kubeadm=1.17.8-00 kubectl=1.17.8-00
sudo apt-mark hold docker-ce kubelet kubeadm kubectl

# add ip tables
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf

# enable iptables immediately
sudo sysctl -p


cat <<EOF


     finished installing.......

     ### on master nodes run these commands ###
     # initialize cluster and add calico CNI network overlay
     # sudo kubeadm init --pod-network-cidr=10.244.0.0/16
     # kubectl apply -f https://docs.projectcalico.org/v3.14/manifests/calico.yaml


EOF
