#!/bin/bash

# See lab configuration in the file referenced below.
source ../configuration.sh

# Download Longhorn Helm chart
echo "Downloading Longhorn heml chart ..."
LONGHORNURL="https://github.com/longhorn/charts/releases/download/longhorn-1.8.1/longhorn-1.8.1.tgz"
curl -O -L ${LONGHORNURL}

# Extracting cert-manager helm chart files.
echo "Removing old Heml chart files ..."
rm -R ./longhorn
echo "Extracting new Helm chart files ..."
tar -xvzf ./longhorn-1.8.1.tgz


echo "Installing Hem chart from local folder ..."
helm install longhorn ./longhorn --namespace longhorn-system --create-namespace --wait -f ./values-custom.yaml

echo "Please wait 2-5 minutes for all the longhorn pods initialize. Look for pods like csi-* "

echo "Wait for 60 seconds for the default storage to initialize. Monitor longhorn dashboard, wait till all default volumes are healthy."
sleep 60

CURRENTAGENTNODE=0
for newnode in "${K3SAGENTHOSTS[@]}"; do
  echo "Patching disk configuration for node $newnode ..."
  kubectl -n longhorn-system patch node.longhorn.io ${newnode} --type merge --patch-file ./datadisks-patch.yaml
  echo "Patching disk configuration for node $newnode done."

  ((CURRENTAGENTNODE++))
done
