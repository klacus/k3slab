#!/bin/bash

# This file has the configuration details to build the lab environment.
# This should be the only file you need to edit before deployment.

# K3s nodes. Virtual machine names, static IP and MAC addresses.
# These host entries must be present in the DHCP server of the local network as static entries and registered with the DNS server also to be resolvable.
# Recommended to use OPNsense (https://opnsense.org/) or pfSense (https://www.pfsense.org/) or Sophos Firewall Home Edition (https://www.sophos.com/en-us/free-tools/sophos-xg-firewall-home-edition) or other firewall / router software or appliance that provides DNS, DHCP, Virtual IP and load balancing services.
# The arrays for ...HOSTS, ...IPS and ...MACS variables must match in the number of entries and align in position.
# The VMs will have these MAC addresses to match DHCP static IP assignments to get the same IP address every time. 
# The hostnames must match the static host entries 
# You need to set up the static assignments in your router/firewall/DHCP server. Or your router if that is assigning IP addresses.

# The Server (a.k.a. master) nodes.
K3SSERVERHOSTS=(lab-k3sm1 lab-k3sm2 lab-k3sm3)
K3SSERVERIPS=("192.168.1.201" "192.168.1.202" "192.168.1.203" )
K3SSERVERIMACS=("52:54:00:c4:e6:25" "52:54:00:cb:f4:a8" "52:54:00:94:33:8b")
# The Agent (a.k.a. worker) nodes.
K3SAGENTHOSTS=(lab-k3sw1 lab-k3sw2 lab-k3sw3)
K3SAGENTIPS=("192.168.1.204" "192.168.1.205" "192.168.1.206")
K3SAGENTMACS=("52:54:00:25:79:40" "52:54:00:f4:ab:cd" "52:54:00:f4:ab:ce")

# The Virtual IP and the hostname of the K3s lab Kubernetes cluster. We will use these for load balancing, managing K3s and accessing workload.
# The K3s cluster FQDN.
K3SCLUSTERFQDN="lab-k3s.perihelion.lan" 
# The cluster virtual IP (VIP).
K3SCLUSTERIP="192.168.1.209" 

# The context name of your K3s lab cluster in the .kube/config file.
# Change this to your liking / preferred one or leave it the default.
K3SCONTEXT="lab-k3s"

# Node monitoring settings (default node not ready is 5 minutes which is a very long time even in development)
NOTREADYSECONDS=30     # default-not-ready-toleration-seconds
UNREACHEABLESECONDS=30 # default-unreachable-toleration-seconds
MONITORPERIOD=20s      # node-monitor-period
MONITORGRACEPERIOD=20s # node-monitor-grace-period
NODEUPDATEFREQUENCY=5s # node-status-update-frequency

# K3s pod eviction is 5 minute default. We change this to 10 seconds --kube-controller-manager-arg pod-eviction-timeout=10s
# This is not used as the setting does not seem to work with K3s 1.32.3
# PODEVICTIONTIMEOUT=10 # --kubelet-arg pod-eviction-timeout=${PODEVICTIONTIMEOUT}

# The name of the SSH key file. This is the SSH key file we will use to connect to the nodes to install / maintain K3s.
SSHKEYFILE="labk3s"

# The ssh configuration file. 
SSHCONFIGFILE=~/.ssh/config
# This is the entry in the ssh config to disable strict host checking that is required for smooth automation.
# !!! IMPORTANT: Do not use this in anywhere else than in a home lab or other than development environment.
# It is recommended to take it out from the ssh config file after the lab is built.
NOHOSTCHECKING="StrictHostKeyChecking no"

# This is the user account on your VMs, and in the template VM image.
VMUSER="developer" 

# To show or hide libguestfs debug messages.
# Exporting it needed!
export DEBUGVMBUILD="no"

# The fully qualified file name of the template VM image that will be used to create the K3s virtual machines using cloning.
VMTEMPLATEFILE="/vm/vms/lab-k3s-template.qcow2"

# Fully qualified path to the folder where the K3s lab VM files will be stored on your system.
VMIMAGEFOLDER="/vm/vms"

# File name extension for the VM image files. This should not change from the default if using QEMU/KVM.
NEWVMFILEEXTENSION="qcow2"

# This is the group owning the VM image files. This should not change from the default if using QEMU/KVM.
OSVMGROUP="kvm"

# K3s Server (a.k.a. master) CPU and RAM size.
SERVERRAM=2048
SERVERCPU=2

# K3s Agent (a.k.a. worker) CPU and RAM size.
AGENTRAM=6144
AGENTCPU=2

# This should match the Linux distribution you used to build the template image.
VMOSVARIANT="debian12"

# Virtual machine network configuration. 
# The name of the bridge device you configured to allow the VMs to connect to your network.
# Bridged device is needed to get a static IP from DHCP (and IPs to register with DNS) for load balancing to work properly. 
# The VMs should show up on the network as any other physical device. NAT-ed connection will not work.
VMNETWORKBRIDGE="bridge0"

# The network model for the VM. This should not change from the default if using QEMU/KVM.
VMNETWORKMODEL="virtio"

# The network name for the VM. This should not change from the default if using QEMU/KVM unless you created a specific network for your lab.
VMNETWORKNAME="default"

# The display server type. This should not change from the default if using QEMU/KVM. 
# We not using this type of connection, but the parameter is required for the VM registration (virt-install)
VMGRAPHICS="spice"

# Mitigate virt-sysprep issues with fixing FQDN in /etc/hosts. 
# The tool (virt-sysprep) uses the hostname but not the FQDN as of 2025.03.30 v1.52.0.
# This must match the host name of the template VM you use to clone all the other lab VMs from.
TEMPLATEHOSTNAME="lab-k3s-template"

# The location and version of the k3sup tool used to deploy K3s.
# You may need to change version number to use the latest one.
K3SUPDLROOT="https://github.com/alexellis/k3sup/releases/download/"
K3SUPVERSION="0.13.8"


# The export for the KUBECONFIG is necessary so all tools access the K3s cluster.
export KUBECONFIG=~/.kube/k3slab
