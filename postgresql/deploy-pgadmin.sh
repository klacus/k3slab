#!/bin/bash

source ../configuration.sh

PGADMINURL="https://helm.runix.net/pgadmin4-1.39.2.tgz"

echo "Removing old PgAdmin ..."
helm uninstall pgadmin4 -n hello
# The secret for the ingress that contains the certificate is not removed when ingress is removed...
kubectl delete secret pgadmin4-tls -n hello

echo "Waiting 15 seconds for the old permanent volume to clean up ..."
sleep 15

echo "Download PgAdmin chart ..." 
curl -L -O ${PGADMINURL}

echo "Extracting PgAdmin chart ..." 
tar -xvzf ./pgadmin4-1.39.2.tgz

echo "Installing PgAdmin ..."
helm upgrade --install pgadmin4 --namespace hello -f ./values-pgadmin4.yaml --wait ./pgadmin4

echo "Waiting 15 seconds for the cluster to be ready ..."
sleep 15

echo "Run Helm Tests ..."
helm test --namespace hello pgadmin4
