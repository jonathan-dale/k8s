#!/bin/bash


function abort {
  EXIT_VAL="$?"
  echo "ABORT ERROR: $EXIT_VAL occurred, failed to execute '$BASH_COMMAND' line ${BASH_LINENO[0]}"
  exit "$EXIT_VAL"
}


function usage {
  EXIT_VAL="${1:-0}"
  MESS="$2"
  SCRIPT="$(basename $0)"
  
  cat <<-EOF
	
	
	USAGE: $SCRIPT args
	
	   Args:
	   master	-  if this is a controler node
	   worker	-  if this is a worker node
	
	
	This is a kubernetes cluster installer, it will install and enable
	the k8's binaries, docker, and configure firewall ports needed to
	join the cluster.
	Use arg to choose worker or control plane nodes.
	
	
	
	EOF
  
  [[ -z "$MESS" ]] || echo -e 1>&2 "$MESS\n"
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

# are we building a master or worker node
NODE_TYPE=$1

  ## TODO - add arg checking
[[ -z "$NODE_TYPE" ]] && usage 1 "ERROR -- You must specify master or worker node"


function install_docker {
  echo " [ FUNCTION: install_docker $NODE_TYPE ] -- installing docker for $NODE_TYPE node"  
  yum install -y yum-utils device-mapper-persistent-data lvm2
  yum-config-manager --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
  yum update -y && yum install -y \
    containerd.io-1.2.13 \
    docker-ce-19.03.11 \
    docker-ce-cli-19.03.11
  mkdir /etc/docker
  cat > /etc/docker/daemon.json <<-EOF
  {
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
      "max-size": "100m"
    },
    "storage-driver": "overlay2",
    "storage-opts": [
      "overlay2.override_kernel_check=true"
    ]
  }
EOF
  
  mkdir -p /etc/systemd/system/docker.service.d
  systemctl daemon-reload
  systemctl restart docker
  systemctl enable docker
}


function install_k8s {
  echo "[ FUNCTION: install_k8s $NODE_TYPE ] -- installing k8's bins for $NODE_TYPE node"
  rpm --import https://packages.cloud.google.com/yum/doc/yum-key.gpg
  cat > /etc/yum.repos.d/kubernetes.repo <<-EOF
  [kubernetes]
  name=Kubernetes
  baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
  enabled=1
  gpgcheck=1
  repo_gpgcheck=1
  gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
  yum install -y kubelet kubeadm kubectl
  systemctl start kubelet
  systemctl enable kubelet
  
}


function master_node {
  echo "[ FUNCTION: master_node $NODE_TYPE ] -- INSTALLING MASTER NODE SPECIFIC FIREWALL ITEMS $NODE_TYPE node"
  HOSTNAMECTL=`hostnamectl`
  [[ ! -z $HOSTNAMECTL ]] || die "must install hostnamectl" 1 ## yum install -y hostnamectl
  hostnamectl set-hostname master-node
  
    ## TODO 
  ## make a hosts DNS record to resolve the hostname for all the nodes
      #### example
  	# vi /etc/hosts
  	# 192.168.1.10 master.phoenixnap.com master-node
  	# 192.168.1.20 node1. phoenixnap.com node1 worker-node
  FIREWALL_CMD=`which firewall-cmd`
  [[ -z $FIREWALL_CMD ]] || die "must install and enable firewalld" 1 ## yum install -y firewalld
  
  ### master node only
  firewall-cmd --permanent --add-port=6443/tcp
  firewall-cmd --permanent --add-port=2379-2380/tcp
  firewall-cmd --permanent --add-port=10250/tcp
  firewall-cmd --permanent --add-port=10251/tcp
  firewall-cmd --permanent --add-port=10252/tcp
  firewall-cmd --permanent --add-port=10255/tcp
  firewall-cmd --reload
}


function worker_node {
  echo "[ FUNCTION: worker_node $NODE_TYPE ] -- installing worker node specific firewall items for $NODE_TYPE node"
  HOSTNAMECTL=`hostnamectl`
  [[ ! -z $HOSTNAMECTL ]] || die "must install hostnamectl" 1 ## yum install -y hostnamectl
  hostnamectl set-hostname worker-node
  
  FIREWALL_CMD=`which firewall-cmd`
  [[ -z $FIREWALL_CMD ]] || die "must install and enable firewalld" 1 ## yum install -y firewalld
  
  firewall-cmd --permanent --add-port=10251/tcp
  firewall-cmd --permanent --add-port=10255/tcp
  firewall-cmd --reload
}


function iptables {
  echo "[ FUNCTION: iptables $NODE_TABLES ] -- installing iptables for $NODE_TYPE node"
  cat <<-EOF > /etc/sysctl.d/k8s.conf
  net.bridge.bridge-nf-call-ip6tables = 1
  net.bridge.bridge-nf-call-iptables = 1
EOF
  sysctl --system
  
  ## disable selinux
  setenforce 0
  sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
  
  ## disable swap
  sed -i '/swap/d' /etc/fstab
  swapoff -a
}


function deploy_cluster {
  echo "[ FUNCTION: deploy_cluster $NODE_TYPE ] -- deploying cluster for $NODE_TYPE node"
  kubeadm init --pod-network-cidr=10.244.0.0/16
  mkdir -p $HOME/.kube
  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config
  
  ## set up pod network w/ flannel
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
}



### logic
install_docker
install_k8s
# based on user input
[[ $NODE_TYPE == master ]] && master_node
[[ $NODE_TYPE == worker ]] && worker_node

iptables
[[ $NODE_TYPE == master ]] && deploy_cluster


