#!/bin/bash

# Download Rancher helm chart.
curl -O -L https://releases.rancher.com/server-charts/stable/rancher-2.10.3.tgz
# remove old folder and content 
rm -R ./rancher-2.10.3.tgz
# Extracting helm chart files.
tar -xvzf ./rancher-2.10.3.tgz

# echo "Remove existing DB cluster ..."
helm uninstall rancher -n cattle-system --wait

echo "Install Rancher ..."
helm upgrade --install --namespace cattle-system --create-namespace --wait -f ./values-custom-rancher.yaml rancher ./rancher
