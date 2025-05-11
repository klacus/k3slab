#!/bin/bash

# Description
# This and the other scripts was inspired by the work of "Jims Turland" work at https://github.com/JamesTurland/JimsGarage/blob/main/Kubernetes/K3S-Deploy/k3s.sh
# The aim is to build a budget friendly local K8s lab (likely on your local machine, Linux OS expected) and use an external load balancer on the local network and not required assign or block an IP range in DHCP for each service running on K3s. 
# More like a cloud load balancer on the local network that has one Virtual IP (VIP) for the entire K3s cluster and handle routing to K8s services within the cluster based on host hearer and/or path. See OPNSense os-relayd for VIP.

# !!!! WARNINGS and ASSUMPTIONS !!!!
#
# These scripts are meant to build a simple, budget home lab environment to learn Kubernetes through K3s. Not meant for production usage or to be exposed to the Internet. You have been warned!
# A Linux OS (Linux Mint 22.1 tested with kernel 6.11.0-19-generic) to host the VMs in QEMU.
# Basic QEMU virtualization on your local host or machine you run this script. If you have ProxMox or similar tool, you need to use another tool or script.
# The use of an external Router, DNS and DHCP Server configured for static IPs for K3s nodes.
# You run this script as root (sudo is OK). the virt-sysprep tool needs access to local kernel modules and files for some reason. The K3s install needs to happen as root on the nodes and passwordless SSH login needs to be enabled on the nodes for the automated install.
# This script will assume that you building or rebuilding an environment, so it will overwrite files without warning.
# A template VM image created earlier and set up to be cloned to build the K3s nodes and has a basic OS (Debian 12 tested) installed with active SSH server and no swap partition.
# The template VM does not have a swap partition, as then the cloned VM startup will be extremely slow every time. Some bug in these scripts or in virt-sysprep.
# The hostname within the VM and the template image are the same as the VM name (like labk3sm1).
# The VM image file names are the same as the VM hostname and the VM name in QEMU.

# Description:
# This script will create the virtual machines from a template VM file and the extra data files for the K3s lab VMs.
# !!! IMPORTANT: This script needs to run as root due to virt-sysprep's requirement to read host operating system kernel files.

# See lab configuration in the file referenced below.
source ../configuration.sh

# Generate SSH key pairs. This key is used to connect to the Vms later without password.
if [[ ! -f ~/.ssh/${SSHKEYFILE} ]] || [[ ! -f ~/.ssh/${SSHKEYFILE}.pub ]]; then 
  echo "SSH key files (~/.ssh/${SSHKEYFILE} ~/.ssh/${SSHKEYFILE}.pub) do not exist. Creating ..."
  # rm ~/.ssh/${SSHKEYFILE}*
  # Generate new set of SSH key files
  ssh-keygen -q -t rsa -b 4096 -f ~/.ssh/${SSHKEYFILE} -N "" -C "K3s lab SSH key file for node management."
else
  echo "SSH keyfiles exist."
  ls -laR ~/.ssh
fi

# Create new VM nodes for servers and agents.
# Creating Server VM nodes.
CURRENTSERVERNODE=0
for NEWNODE in "${K3SSERVERHOSTS[@]}"; do
  echo "Cloning $NEWNODE from '${VMTEMPLATEFILE}' ..."
  echo "IP: ${K3SSERVERIPS[$CURRENTSERVERNODE]}"
  echo "MAC: ${K3SSERVERIMACS[$CURRENTSERVERNODE]}"

  NEWVMFILE=${VMIMAGEFOLDER}/${NEWNODE}.${NEWVMFILEEXTENSION} 
  echo "New VM file: ${NEWVMFILE}"
  NEWVMMAC=${K3SSERVERIMACS[$CURRENTSERVERNODE]}

  ./newk3snode.sh $NEWNODE ${VMTEMPLATEFILE} ${NEWVMFILE} ${OSVMGROUP} ${SERVERRAM} ${SERVERCPU} ${VMOSVARIANT} ${VMNETWORKBRIDGE} ${VMNETWORKNAME} ${NEWVMMAC} ${VMGRAPHICS} ${SSHKEYFILE} ${VMUSER} ${TEMPLATEHOSTNAME} no

  ((CURRENTSERVERNODE++))
done

# Creating Agent VM nodes.
CURRENTAGENTNODE=0
for NEWNODE in "${K3SAGENTHOSTS[@]}"; do
  echo "Cloning $NEWNODE from '${VMTEMPLATEFILE}' ..."
  echo "IP: ${K3SAGENTIPS[$CURRENTAGENTNODE]}"
  echo "MAC: ${K3SAGENTMACS[$CURRENTAGENTNODE]}"

  NEWVMFILE=${VMIMAGEFOLDER}/${NEWNODE}.${NEWVMFILEEXTENSION} 
  echo "New VM file: ${NEWVMFILE}"
  NEWVMMAC=${K3SAGENTMACS[$CURRENTAGENTNODE]}
 
  ./newk3snode.sh $NEWNODE ${VMTEMPLATEFILE} ${NEWVMFILE} ${OSVMGROUP} ${AGENTRAM} ${AGENTCPU} ${VMOSVARIANT} ${VMNETWORKBRIDGE} ${VMNETWORKNAME} ${NEWVMMAC} ${VMGRAPHICS} ${SSHKEYFILE} ${VMUSER} ${TEMPLATEHOSTNAME} yes 

  ((CURRENTAGENTNODE++))
done
