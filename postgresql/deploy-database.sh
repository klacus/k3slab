#!/bin/bash

source ../configuration.sh

DBCLUSTERURL=https://github.com/cloudnative-pg/charts/releases/download/cluster-v0.3.0/cluster-0.3.0.tgz

echo "Download DB cluster chart ..."
curl -L -O ${DBCLUSTERURL}

# Extracting CloudnativePG helm chart files.
echo "Removing old Heml chart files ..."
rm -R ./cluster
echo "Extracting new Helm chart files ..."
tar -xvzf ./cluster-0.3.0.tgz

# Uninstall
echo " Uninstall DB cluster ..."
helm uninstall k3slabsql -n hello --wait

# echo "Wait 90 seconds for everything to clean up..."
# sleep 90 

echo "Install DB cluster ..."
helm upgrade --install --namespace hello --create-namespace -f ./values-custom-cluster.yaml --wait k3slabsql ./cluster

echo "Waiting 60 seconds for the cluster to be ready ..."
sleep 60

echo "Run Helm Tests ..."
helm test --namespace hello k3slabsql

echo "Get a list of all base backups:"
# kubectl --namespace hello get backups --selector cnpg.io/cluster=k3slabsql-cluster

# echo "Connect to the cluster's primary instance:"
# kubectl --namespace hello exec --stdin --tty services/k3slabsql-cluster-rw -- bash
