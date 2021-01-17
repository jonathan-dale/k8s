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


#### Install [Kubectx](https://github.com/ahmetb/kubectx) to change namespaces and contexts in k8's cluster

###### Linux
```bash
    sudo apt install kubectx

		** OR ** 

    git clone https://github.com/ahmetb/kubectx.git ~/.kubectx
    sudo cp kubectx/kubectx /usr/local/bin/
    sudo cp kubectx/kubens /usr/local/bin/
    COMPDIR=$(pkg-config --variable=completionsdir bash-completion)
    ln -sf ~/.kubectx/completion/kubens.bash $COMPDIR/kubens
    ln -sf ~/.kubectx/completion/kubectx.bash $COMPDIR/kubectx
    cat << FOE >> ~/.bashrc
    
    
    #kubectx and kubens
    export PATH=~/.kubectx:\$PATH
    FOE

```

###### macOS
If you use [Homebrew](https://brew.sh/) you can install like this:

    brew install kubectx

That ^^^ will set up bash/zsh/fish completion scripts automatically.


