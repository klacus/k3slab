#!/bin/bash

# See lab configuration in the file referenced below.
source ../configuration.sh

#  Reference URLs: 
# https://artifacthub.io/packages/helm/chartmuseum/chartmuseum?modal=install
# https://chartmuseum.com/
# https://github.com/helm/chartmuseum

# Download Chartmuseum Helm chart
echo "Downloading Longhorn heml chart ..."
PACKAGE=chartmuseum-3.10.4.tgz
REPOURL="https://github.com/chartmuseum/charts/releases/download/chartmuseum-3.10.4/${PACKAGE}"
curl -O -L ${REPOURL}

# Extracting cert-manager helm chart files.
echo "Removing old Heml chart files ..."
rm -R ./chartmuseum
echo "Extracting new Helm chart files ..."
tar -xvzf ./${PACKAGE}

helm uninstall chartmuseum --namespace chartmuseum 

echo "Waiting for 60 seconds to allow resources to be cleaned up ..."
sleep 60

echo "Installing Helm chart from local folder ..."
helm install chartmuseum ./chartmuseum --namespace chartmuseum --create-namespace --wait -f ./values-custom.yaml
