# K8's installation and notes

## scripts to install k8's cluster on Ubuntu or CentOS, and a backup cluster script

##### may not be updated or tested after Nov 2020

# install autocompletion

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

