#!/bin/bash

# Turn of all swapping. Recommended for K3s. 
# See: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#swap-configuration
cat <<EOF >/etc/sysctl.d/k8s.conf
vm.swappiness = 0
EOF

# Apply the sysctl changes.
sysctl --system

