# Use this to create the install script.


Kubernetes cluster install on linuxacademy.com
Spin up three UBUNTU servers:  master-1, node-1, and node-2


Install packages on all hosts in cluster

### add Docker GPG key and repo
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository \
	   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	   $(lsb_release -cs) \
	   stable"

### update and upgrade
	sudo apt-get update -y && sudo apt-get upgrade -y

### install docker-ce
	sudo apt-get install -y docker-ce
	sudo apt-mark hold docker-ce

	** Note **  The linux academy class uses docker-ce=18.06.1~ce~3-0~ubuntu; I just installed docker-ce
	


### install Kubernetes GPG key and repo
	curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
	cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
	deb https://apt.kubernetes.io/ kubernetes-xenial main
	EOF

	sudo apt-get update
	sudo apt-get install -y kubelet=1.15.7-00 kubeadm=1.15.7-00 kubectl=1.15.7-00
	sudo apt-mark hold kubelet kubeadm kubectl
	kubeadm version
	ln -s /usr/bin/kubectl /usr/bin/k

	** Note ** the class uses versions above, but I just used the latest versions 



## Bootstrap the cluster

### On the all of the master-nodes initialize the cluster.
*** Note *** after ‘kubeadm init’ command outputs a join command and token

	sudo kubeadm init --pod-network-cidr=10.244.0.0/16

** Note ** after ‘kubeadm init’ command is finished keep the cluster join command and token


##########################################################################################
##########################################################################################
	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	CLUSTER JOIN COMMAND AND TOKEN
	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 172.31.123.86:6443 --token 2o6ecp.8tectimt1t31dwqd \
    --discovery-token-ca-cert-hash sha256:caa4c83bbabb8da7272936951ace68df84132d50dc6ee3fe99c584a8c33cac30
##########################################################################################
##########################################################################################


### create .kube/config file
	mkdir -p $HOME/.kube
	sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	sudo chown $(id -u):$(id -g) $HOME/.kube/config


### Confirm you see ‘client version’ and ‘server version’
	k version

Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.6", GitCommit:"dff82dc0de47299ab66c83c626e08b245ab19037", GitTreeState:"clean", BuildDate:"2020-07-15T16:58:53Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.6", GitCommit:"dff82dc0de47299ab66c83c626e08b245ab19037", GitTreeState:"clean", BuildDate:"2020-07-15T16:51:04Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}



### Join worker nodes to cluster
	sudo kubeadm join 172.31.123.86:6443 --token 2o6ecp.8tectimt1t31dwqd \
    --discovery-token-ca-cert-hash sha256:caa4c83bbabb8da7272936951ace68df84132d50dc6ee3fe99c584a8c33cac30


### check the cluster
	K get nodes
	K get pods —all-namespaces

** Note ** nodes will have status of “NotReady” at this point


Setup netowrking

## we will use flannel network plugin: https://coreos.com/flannel/docs/latest/

### Set sysctl value on all hosts in cluster
	sudo echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf
	sudo sysctl -p


### Install flannel — Only on the Master!
	k apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
	

### Verify nodes now have STATUS of Ready
	k get nodes


### Check flannel pods are running 
	k get pods -n kube-system


