#!/bin/bash

# See lab configuration in the file referenced below.
source ../configuration.sh

# We need all the hosts in the cluster and deploy the self signed certificate.
K3SNODES=("${K3SSERVERHOSTS[@]}" "${K3SAGENTHOSTS[@]}")

# Download Custom Resource Definitions.
curl -O -L https://github.com/cert-manager/cert-manager/releases/download/v1.17.1/cert-manager.crds.yaml

# Download cert-manager helm chart.
curl -O -L https://charts.jetstack.io/charts/cert-manager-v1.17.1.tgz

# remove old folder and content of cert-manager 
rm -R ./cert-manager

# Extracting cert-manager helm chart files.
tar -xvzf ./cert-manager-v1.17.1.tgz

# Uninstall existing cert-manager and CRDs if exist.
echo "Uninstalling cert-manager ..."
helm uninstall cert-manager
echo "Uninstalling cert-manager done"

echo "Uninstalling CRDs ..."
kubectl delete -f ./cert-manager.crds.yaml
echo "Cert-manager and CRDs uninstalled."

# Install cert manager with the custom value files
echo "Installing cert manager ..."
kubectl apply -f ./namespace.yaml
helm upgrade --install --create-namespace --wait -f ./values-custom.yaml cert-manager ./cert-manager
echo "Cert-manager installed."

# Bootstrapping CA cert 
echo "Creating Root CA ..."
kubectl apply -f ./selfsigned-ca.yaml --wait
echo "Creating Root CA done."

echo "Waiting 60 seconds for the certificates properly created ..."
sleep 60

# export root CA so it can be imported to local OS and browsers.
echo "Exporting certificates"
kubectl get secret root-secret -n cert-manager -o go-template='{{index .data "ca.crt" | base64decode}}}' > k3slab-ca.crt
kubectl get secret root-secret -n cert-manager -o go-template='{{index .data "tls.crt" | base64decode}}}' > k3slab-tls.crt
kubectl get secret root-secret -n cert-manager -o go-template='{{index .data "tls.key" | base64decode}}}' > k3slab-tls.key

# Deploy the Root CA to K3s nodes.
echo "Deployin root CA to K3s nodes ..."
for node in "${K3SNODES[@]}"; do
  echo "Copy Root CA to K3s node: ${node} ..."
  scp -i ~/.ssh/labk3s ./k3slab-ca.crt root@${node}:/usr/local/share/ca-certificates/

  echo "Adding k3slab-ca.crt to trusted certs on ${node} ..."
  ssh root@${node} "sudo update-ca-certificates"

  echo "Rebooting ${node} to apply new Root CA ..."
  ssh root@${node} "reboot"
done
echo "CA cert loaded to all nodes."

# Add Root CA to local machine trusted certs
echo "Adding Root CA to local machine trusted certs ..."
sudo cp ./k3slab-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
echo .
echo .
echo .
echo "!!! Do not forget to import the ./k3slab-ca.crt certificate to your browser! !!!"
echo .
echo .
echo .

# Installing Trust Manager
# https://cert-manager.io/docs/trust/trust-manager/

# uninstall Trust Manager if needed

# install trust manager

echo !!!
echo !!!
echo !!!
echo If you have docker running, you will need to restart it to pick up the new CA certificate.
echo "sudo systemctl restart docker.service"
sudo systemctl restart docker.service
echo !!!
echo !!!
echo !!!

echo "Done."
