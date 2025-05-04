#!/bin/bash

source ../configuration.sh

OPERATORURL=https://github.com/cloudnative-pg/charts/releases/download/cloudnative-pg-v0.23.2/cloudnative-pg-0.23.2.tgz

echo "Download CloudnativePG chart ..."
curl -L -O ${OPERATORURL}

echo "Removing old Heml chart files ..."
rm -R ./cloudnative-pg

echo "Extracting new Helm chart files ..."
tar -xvzf ./cloudnative-pg-0.23.2.tgz

echo "Removing old CloudnativePG ..."
helm uninstall cloudnative-pg -n cnpg-system --wait

echo "Install opereator ..."
helm upgrade --install cloudnative-pg --namespace cnpg-system --create-namespace -f ./values-custom-operator.yaml --wait ./cloudnative-pg
