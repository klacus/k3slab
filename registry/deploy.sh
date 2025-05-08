#!/bin/bash

source ../configuration.sh

helm uninstall registry -n registry
echo "Longhorn will take some time to remove permanent volume waiting 30 seconds ..."
sleep 30 
helm upgrade registry ./chart --install --namespace registry --create-namespace -f ./values-custom.yaml

echo "Waiting 30 seconds for the registry and the certificate to deploy properly ..."
sleep 30 
curl https://registry.services.labk3s.perihelion.lan/v2/_catalog

echo "Restarting local docker service to pick up the CA certificate deployed with cert-manager ..."
# This is to support image pust from local docer to your image registry.
sudo systemctl restart docker.service
echo "Done."
