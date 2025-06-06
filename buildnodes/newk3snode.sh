#!/bin/bash

NEWNAME=$1
TEMPLATE=$2
NEWFILE=$3
OSVMGROUP=$4 
VMRAM=$5
VMCPU=$6
VMOSVARIANT=$7
VMNETWORKBRIDGE=$8
VMNETWORKNAME=$9
VMMAC=${10}
VMGRAPHICS=${11}
SSHKEYFILE=${12}
VMUSER=${13}
TEMPLATEHOSTNAME=${14}

echo "Creating new WM image ${NEWFILE} from ${TEMPLATE} ..."
cp -f ${TEMPLATE} ${NEWFILE}
chown ${USER}:${OSVMGROUP} ${NEWFILE}

# enable debugging
if [[ "${DEBUGVMBUILD}" == "yes"  ]]; then
  export LIBGUESTFS_DEBUG=1 LIBGUESTFS_TRACE=1 BUILDFLAGS=" -v -x "
else
  export LIBGUESTFS_DEBUG=0 LIBGUESTFS_TRACE=0 BUILDFLAGS=""
fi

# Create extra (additional to OS) disk for permanent volumes
DATAFILE="/vm/vms/${NEWNAME}-data.qcow2"
DISKUUID=$(uuid)
rm -f ${DATAFILE}
qemu-img create -f qcow2 -o preallocation=full ${DATAFILE} 10G
parted ${DATAFILE} mklabel gpt
mkfs.ext4 -F ${DATAFILE} -U "${DISKUUID}"
parted ${DATAFILE} print

# Sysprep image
echo "Sysprep ${NEWFILE} ..."
virt-sysprep ${BUILDFLAGS} \
  --enable customize \
  --operations all,-user-account,-ssh-userdir,-ssh-hostkeys \
  --add ${NEWFILE} \
  --hostname ${NEWNAME} \
  --network \
  --install sudo,curl,mc,open-iscsi,cryptsetup,nfs-common \
  --run ./postscript.sh \
  --run-command "usermod -a -G sudo ${VMUSER}" \
  --run-command "if [ ! -e /root/.ssh/ ]; then  mkdir -p /root/.ssh ; fi" \
  --upload ~/.ssh/${SSHKEYFILE}.pub:/root/.ssh/authorized_keys \
  --run-command "if [ ! -e /home/${VMUSER}/.ssh/ ]; then  mkdir -p /home/${VMUSER}/.ssh ; fi" \
  --upload ~/.ssh/${SSHKEYFILE}.pub:/home/${VMUSER}/.ssh/authorized_keys \
  --run-command "chown -R ${VMUSER}:${VMUSER} /home/${VMUSER}/.ssh" \
  --run-command "chmod 700 /home/${VMUSER}/.ssh" \
  --run-command "sed -i 's/$TEMPLATEHOSTNAME/$NEWNAME/g' /etc/hosts" \
  --run-command "echo '${VMUSER} ALL=(ALL:ALL) NOPASSWD:ALL'>/etc/sudoers.d/k3s" \
  --run-command "mkdir /mnt/data" \
  --run-command "echo 'UUID=${DISKUUID} /mnt/data ext4 defaults 0 0' >> /etc/fstab"

echo "Importing VM ${NEWNAME} to QEMU ..."

virt-install \
  --import \
  --name=${NEWNAME} \
  --disk=${NEWFILE} \
  --disk=${DATAFILE} \
  --os-variant=${VMOSVARIANT} \
  --ram=${VMRAM} \
  --vcpus=${VMCPU} \
  --network=bridge=${VMNETWORKBRIDGE},model=${VMNETWORKMODEL},mac=${VMMAC} \
  --graphics=${VMGRAPHICS} \
  --noautoconsole
