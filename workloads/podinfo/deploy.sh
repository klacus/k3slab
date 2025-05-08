#!/bin/bash

source ../../configuration.sh

echo "Removing old installation ..."
kubectl delete -f podinfo.yaml --wait
# the cert secret must be manually removed
kubectl delete secret podinfo-cert -n hello --wait

echo "Deploying ..."
kubectl apply -f namespace.yaml --wait
kubectl apply -f podinfo.yaml --wait

kubectl delete -f gateway.yaml --wait
kubectl apply -f gateway.yaml --wait
