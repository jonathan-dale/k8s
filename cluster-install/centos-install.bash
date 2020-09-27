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

# are we building a master or worker node
NODE_TYPE=$1

  ## TODO - add arg checking
[[ -z "$NODE_TYPE" ]] && usage 1 "ERROR -- You must specify master or worker node"


function install_docker {
  
  sudo yum install -y yum-utils device-mapper-persistent-data lvm2
  sudo yum-config-manager --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
  sudo yum update -y && yum install -y \
    containerd.io-1.2.13 \
    docker-ce-19.03.11 \
    docker-ce-cli-19.03.11
  sudo mkdir /etc/docker
  sudo cat > /etc/docker/daemon.json <<EOF
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
  
  sudo mkdir -p /etc/systemd/system/docker.service.d
  sudo systemctl daemon-reload
  sudo systemctl restart docker
  sudo systemctl enable docker
}


function install_k8s {
  sudo rpm --import https://packages.cloud.google.com/yum/doc/yum-key.gpg
  cat > /etc/yum.repos.d/kubernetes.repo <<EOF
  [kubernetes]
  name=Kubernetes
  baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
  enabled=1
  gpgcheck=1
  repo_gpgcheck=1
  gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
  EOF
  sudo yum install -y kubelet kubeadm kubectl
  sudo systemctl start kubelet
  sudo systemctl enable kubelet
  
}



### logic
install_docker
instal_k8s


 
##  ## TODO - function for master and worker
##  ### now set this one up as a master or worker node
##  HOSTNAMECTL=`which hostnamectl`
##  [[ -z $HOSTNAMECTL ]] || echo -e 1>&2 "must install hostnamectl" exit 1 ## sudo yum install -y hostnamectl
##  sudo hostnamectl set-hostname worker-node
##  
##    ## TODO 
##  ## make a hosts DNS record to resolve the hostname for all the nodes
##      #### example
##  	# sudo vi /etc/hosts
##  	# 192.168.1.10 master.phoenixnap.com master-node
##  	# 192.168.1.20 node1. phoenixnap.com node1 worker-node
##  
##  
##  
##  ## configure firewalld
##  FIREWALLCMD=`which firewall-cmd`
##  [[ -z $FIREWALLCMD ]] || echo -e 1>&2 "must install and enable firewalld" exit 1
##  
##  ### master node only
##  sudo firewall-cmd --permanent --add-port=6443/tcp
##  sudo firewall-cmd --permanent --add-port=2379-2380/tcp
##  sudo firewall-cmd --permanent --add-port=10250/tcp
##  sudo firewall-cmd --permanent --add-port=10251/tcp
##  sudo firewall-cmd --permanent --add-port=10252/tcp
##  sudo firewall-cmd --permanent --add-port=10255/tcp
##  sudo firewall-cmd --reload
##  
##  ### worker nodes
##  sudo firewall-cmd --permanent --add-port=10251/tcp
##  sudo firewall-cmd --permanent --add-port=10255/tcp
##  firewall-cmd --reload
##  
##  ## update iptables settings
##  cat <<-EOF > /etc/sysctl.d/k8s.conf
##  net.bridge.bridge-nf-call-ip6tables = 1
##  net.bridge.bridge-nf-call-iptables = 1
##  EOF
##  sysctl --system
##  
##  
##  ## disable selinux
##  sudo setenforce 0
##  sudo sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
##  
##  
##  ## disable swap
##  sudo sed -i '/swap/d' /etc/fstab
##  sudo swapoff -a
##  
##  
##  #### deploy cluster
##  sudo kubeadm init --pod-network-cidr=10.244.0.0/16   ### this may take some time, SAVE THE JOIN MESSAGE AND TOKEN, use to join other nodes to cluster.
##  
##  
##  ## make .kube/config
##  mkdir -p $HOME/.kube
##  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
##  sudo chown $(id -u):$(id -g) $HOME/.kube/config
##  
##  
##  ## set up pod network w/ flannel
##  sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
##  
##  
##  ## check status of cluster
##  ## when flannel install finishes check for CoreDNS pod is up
##  sudo kubectl get nodes
##  sudo kubectl get pods --all-namespaces
##  
##  
##  # join other nodes to cluster  (from kubeadm step ^^^)
##  # kubeadm join --discovery-token cfgrty.1234567890jyrfgd --discovery-token-ca-cert-hash sha256:1234..cdef 1.2.3.4:6443
##  
