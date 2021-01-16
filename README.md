> - Updated and tested as of Dec 20, 2020
> - Current versions:
> - kuebctl, kubeadm, and kubelet current version 1.19.00-xx
# K8's cluster installation, backups, and notes

######
- A cluster installation script (choose Ubuntu or CentOS)
- A cluster backup script

##### Setup commands for a fresh server

- ubuntu
```bash
sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get install -y git && git clone https://github.com/jonathan-dale/k8s.git
```

- centos
```bash
sudo yum update -y && sudo yum upgrade -y && sudo yum install -y git && git clone https://github.com/jonathan-dale/k8s.git
```


##### Kubectl autocompletion
- zsh
```bash
echo 'alias k=kubectl' >>~/.zshrc
echo 'complete -F __start_kubectl k' >>~/.zshrc
```

- bash on linux
```bash
echo 'alias k=kubectl' >>~/.bashrc
echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'complete -F __start_kubectl k' >>~/.bashrc
```


#### Install kubectx to change namespaces and contexts in k8's cluster
-  https://github.com/ahmetb/kubectx

###### Linux
    sudo apt install kubectx

###### macOS
If you use [Homebrew](https://brew.sh/) you can install like this:

    brew install kubectx

That ^^^ command will set up bash/zsh/fish completion scripts automatically.

###### Manal installation steps:
    sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
    sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
    sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

