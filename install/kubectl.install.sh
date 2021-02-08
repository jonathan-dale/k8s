#!/bin/bash

#
# This only installs kubectl, should work on debian and fedora
#

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


function k8s_apt {
  # add K8's GPG key
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

  # add K8's repo
  cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
  deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

  # update and install bins *** Check correct ubuntu distro (focal, bionic...)
  sudo apt-get update
  sudo apt-get install -y kubectl=1.19.0-00
  sudo apt-mark hold kubectl

}


function k8s_yum {
    rpm --import https://packages.cloud.google.com/yum/doc/yum-key.gpg
    cat <<-EOF > /etc/yum.repos.d/kubernetes.repo
	[kubernetes]
	name=Kubernetes
	baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
	enabled=1
	gpgcheck=1
	repo_gpgcheck=1
	gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
    sudo yum install -y kubectl
}


OS_VER=$(cat /etc/os-release | grep NAME | head -1 | cut -d'=' -f2)

[[ $OS_VER =~ Ubuntu ]] && k8s_apt
[[ $OS_VER =~ CentOS ]] && k8s_yum

