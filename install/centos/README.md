# Use this to create the install script

### (Install Docker CE)
   sudo yum install -y yum-utils device-mapper-persistent-data lvm2

### Add the Docker repository
   sudo yum-config-manager --add-repo \
     https://download.docker.com/linux/centos/docker-ce.repo

### Install Docker CE
   yum update -y && yum install -y \
     containerd.io-1.2.13 \
     docker-ce-19.03.11 \
     docker-ce-cli-19.03.11
  sudo mkdir /etc/docker

### Set up the Docker daemon
    cat > /etc/docker/daemon.json <<EOF
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

### Restart Docker
    systemctl daemon-reload
    systemctl restart docker
    
    
    sudo rpm --import https://packages.cloud.google.com/yum/doc/yum-key.gpg
    cat <<EOF > /etc/yum.repos.d/kubernetes.repo
    [kubernetes]
    name=Kubernetes
    baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
    enabled=1
    gpgcheck=1
    repo_gpgcheck=1
    gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
    EOF
    sudo yum install -y kubelet kubeadm kubectl
    sudo systemctl enable kubelet
    sudo systemctl start kubelet


### Helpful links: 
	https://phoenixnap.com/kb/how-to-install-kubernetes-on-centos
	https://kubernetes.io/docs/setup/production-environment/container-runtimes/


### now set this one up as a master or worker node
    sudo hostnamectl set-hostname master-node OR sudo hostnamectl set-hostname worker-node1

### make a hosts DNS record to resolve the hostname for all the nodes
    sudo vi /etc/hosts
    192.168.1.10 master.phoenixnap.com master-node
    192.168.1.20 node1. phoenixnap.com node1 worker-node

### configure firewalld (master node only)
    sudo firewall-cmd --permanent --add-port=6443/tcp
    sudo firewall-cmd --permanent --add-port=2379-2380/tcp
    sudo firewall-cmd --permanent --add-port=10250/tcp
    sudo firewall-cmd --permanent --add-port=10251/tcp
    sudo firewall-cmd --permanent --add-port=10252/tcp
    sudo firewall-cmd --permanent --add-port=10255/tcp
    sudo firewall-cmd --reload

### worker nodes 
    sudo firewall-cmd --permanent --add-port=10251/tcp
    sudo firewall-cmd --permanent --add-port=10255/tcp
    firewall-cmd --reload

### update iptables settings
    cat <<EOF > /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    EOF
    sysctl --system


### disable selinux
    sudo setenforce 0
    sudo sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config


### disable swap
    sudo sed -i '/swap/d' /etc/fstab
    sudo swapoff -a


### deploy cluster
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16   ### this may take some time, SAVE THE JOIN MESSAGE AND TOKEN, use to join other nodes to cluster.


### make .kube/config
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config


### set up pod network w/ flannel
    sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml


### check status of cluster
    sudo kubectl get nodes


### when ^^ that ^^ finishes check that CoreDNS pod is up
    sudo kubectl get pods --all-namespaces



### join other nodes to cluster  (from kubeadm step ^^^)
    kubeadm join --discovery-token cfgrty.1234567890jyrfgd --discovery-token-ca-cert-hash sha256:1234..cdef 1.2.3.4:6443
