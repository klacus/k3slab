#!/bin/bash

# See lab configuration in the file referenced below.
source ../configuration.sh

CURRENTTIME=$(date +"%Y-%m-%d %H:%M:%S")

# Getting SSH keys from root as the VMs were buit by running the script as root.
sudo cp /root/.ssh/${SSHKEYFILE} ~/.ssh/${SSHKEYFILE}
sudo cp /root/.ssh/${SSHKEYFILE}.pub ~/.ssh/${SSHKEYFILE}.pub
MYGID=$(id -g)
sudo chown -R ${UID}:${MYGID} ${HOME}/.ssh

# Disabling strict host checking on the local machine to be able to automated K3s deployment.
# !!! IMPORTANT: Do not use this in anywhere else than in a home lab or other than development environment.
if [[ -f ${SSHCONFIGFILE} ]]; then
  if grep -q "^StrictHostKeyChecking" ${SSHCONFIGFILE}; then
    sed -i "/^StrictHostKeyChecking/ c $NOHOSTCHECKING" ${SSHCONFIGFILE}
  else
    echo "$NOHOSTCHECKING" >> ${SSHCONFIGFILE}
  fi
else
  echo "$NOHOSTCHECKING" >> ${SSHCONFIGFILE}
  chmod 600 ${SSHCONFIGFILE}
fi

# Delete KUBECONFIG
echo "!!! WARNING !!!"
echo "!!! WARNING !!!"
echo "!!! WARNING !!!"
echo " Backing up ${KUBECONFIG} ..."
cp -f ${KUBECONFIG} ${KUBECONFIG}.${CURRENTTIME}
echo "!!! WARNING !!! deleting ${KUBECONFIG} file ..."
rm -f ${KUBECONFIG}
ls -la ~/.kube

# Download latest k3sup into current working folder if it is not present on the system.
# If it is not present we do not install it system wide, hence not using 'curl -sLS https://get.k3sup.dev | sh ...'
if ! command k3sup version 2>&1 >/dev/null; then
  K3SUPURL=${K3SUPDLROOT}${K3SUPVERSION}/k3sup
  echo "Downloading k3sup from ${K3SUPURL} ..."
  curl -sSL ${K3SUPURL} --output "./k3sup"
  chmod u+rwx ./k3sup
fi

# Add current forder to PATH, so we can run k3sup from here. Do not use export we don't want this to stick!
PATH=.:${PATH}

# Create the folder for kubeconfig if it does not exist.
if [[ ! -d ~/.kube ]]; then
  mkdir ~/.kube
fi

# Install the the Server (a.k.a. master) nodes. 
CURRENTSERVERNODE=0
for newnode in "${K3SSERVERHOSTS[@]}"; do

  if [[ ${CURRENTSERVERNODE} -eq 0 ]]; then
    echo "Installing K3s on first Server node: ${newnode}. Creating K3s cluster ..."
    ./k3sup install \
      --k3s-channel stable \
      --host ${K3SSERVERHOSTS[0]} \
      --user ${VMUSER} \
      --context ${K3SCONTEXT} \
      --local-path ${KUBECONFIG} \
      --merge \
      --k3s-extra-args "--tls-san ${K3SCLUSTERFQDN} --tls-san ${K3SCLUSTERIP} --node-taint node-role.kubernetes.io/master=true:NoSchedule --kube-apiserver-arg default-not-ready-toleration-seconds=${NOTREADYSECONDS} --kube-apiserver-arg default-unreachable-toleration-seconds=${UNREACHEABLESECONDS} --kube-controller-arg node-monitor-period=${MONITORPERIOD} --kube-controller-arg node-monitor-grace-period=${MONITORGRACEPERIOD} --kubelet-arg node-status-update-frequency=${NODEUPDATEFREQUENCY}" \
      --cluster \
      --sudo \
      --ssh-key $HOME/.ssh/${SSHKEYFILE}
      # --providers.kubernetesgateway=true 
      # --providers.kubernetesgateway.experimentalchannel=true

# --kube-apiserver-arg feature-gates=GatewayAPI=true

  else
    echo "Installing K3s on additional Server node: ${newnode}. Joining node '${newnode}' to the K3s cluster ..."
    k3sup join \
      --k3s-channel stable \
      --server \
      --host ${K3SSERVERHOSTS[${CURRENTSERVERNODE}]} \
      --user ${VMUSER} \
      --server-host ${K3SSERVERHOSTS[0]} \
      --server-user ${VMUSER} \
      --k3s-extra-args "--tls-san ${K3SCLUSTERFQDN} --tls-san ${K3SCLUSTERIP} --node-taint node-role.kubernetes.io/master=true:NoSchedule --kube-apiserver-arg default-not-ready-toleration-seconds=${NOTREADYSECONDS} --kube-apiserver-arg default-unreachable-toleration-seconds=${UNREACHEABLESECONDS} --kube-controller-arg node-monitor-period=${MONITORPERIOD} --kube-controller-arg node-monitor-grace-period=${MONITORGRACEPERIOD} --kubelet-arg node-status-update-frequency=${NODEUPDATEFREQUENCY}" \
      --sudo \
      --ssh-key $HOME/.ssh/${SSHKEYFILE}
  fi

  ((CURRENTSERVERNODE++))
done

CURRENTAGENTNODE=0
for newnode in "${K3SAGENTHOSTS[@]}"; do
  echo "Installing K3s on Agent node: ${newnode}"

  k3sup join \
    --k3s-channel stable \
    --host ${K3SAGENTHOSTS[${CURRENTAGENTNODE}]} \
    --user ${VMUSER} \
    --server-host ${K3SSERVERHOSTS[0]} \
    --k3s-extra-args "--node-label \"worker=true\" --kubelet-arg node-status-update-frequency=${NODEUPDATEFREQUENCY}" \
    --sudo \
    --ssh-key $HOME/.ssh/${SSHKEYFILE}

  ((CURRENTAGENTNODE++))
done

echo "Waiting for 30 sec for all the nodes to join the cluster properly ..."
sleep 30 
kubectl get nodes

# echo "Enabling experimental Traefik CRDs ..."
# kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/experimental-install.yaml
# curl -L -O https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/experimental-install.yaml
# kubectl apply -f ./experimental-install.yaml

# echo "Enabling Gateway API ..."
# The rbac definition must be modified after download. Change the ClusterRoleBinding ServiceAccount's name and namespace to the following:
# subjects:
#   - kind: ServiceAccount
#     name: traefik
#     namespace: kube-system
# # kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.3/docs/content/reference/dynamic-configuration/kubernetes-gateway-rbac.yml
# curl -L -O https://raw.githubusercontent.com/traefik/traefik/v3.3/docs/content/reference/dynamic-configuration/kubernetes-gateway-rbac.yml
echo "Adding RBAC definitions for Traefik Gateway API implementation ..."
kubectl apply -f ./kubernetes-gateway-rbac.yaml
echo "Patching Traefik deployment to enable Gateway API ..."
kubectl patch deployment traefik -n kube-system --type=json --patch-file ./traefik-patch.yaml
# kubectl patch deployment traefik -n kube-system --type=json --patch-file ./traefik-patch-experimental.yaml

echo "Updating ${KUBECONFIG} with load balanced hostname ..."
sed -i "s/${K3SSERVERHOSTS[0]}/${K3SCLUSTERFQDN}/g" ${KUBECONFIG} 
