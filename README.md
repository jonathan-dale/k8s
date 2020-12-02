# K8's installation and notes

## scripts to install k8's cluster on Ubuntu or CentOS, and a backup cluster script

##### may not be updated or tested after Nov 2020

# Kubectl autocompletion

### zsh
```bash
echo 'alias k=kubectl' >>~/.zshrc
echo 'complete -F __start_kubectl k' >>~/.zshrc
```
### bash on linux
```bash
echo 'source <(kubectl completion bash)' >>~/.bashrc
```
> NOTE: if you have an alias for kubectl - extend completion for that alias
```bash
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -F __start_kubectl k' >>~/.bashrc
```


## kubectx 
#### change namespaces and contexts in k8's cluster
- https://github.com/ahmetb/kubectx

### Installation for macOS
#### Homebrew

If you use [Homebrew](https://brew.sh/) you can install like this:

    brew install kubectx

This command will set up bash/zsh/fish completion scripts automatically.

- If you like to add context/namespace info to your shell prompt (`$PS1`),
  I recommend trying out [kube-ps1](https://github.com/jonmosco/kube-ps1).
