#!/usr/bin/env bash

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# We terminate the TLS at the gateway, so the ArgoCD service can be run in insecure mode.
kubectl -n argocd patch cm argocd-cmd-params-cm --type merge --patch-file ./argocd-cmd-params-cm.yaml

kubectl apply -f ./gateway.yaml

# # Chart location: https://artifacthub.io/packages/helm/argo/argo-cd
# # Download Helm chart
# echo "Downloading helm chart ..."
# CHARTURL="https://github.com/argoproj/argo-helm/releases/download/argo-cd-9.0.5/argo-cd-9.0.5.tgz"
# curl -O -L ${CHARTURL}

# # Extracting helm chart files.
# echo "Removing old Helm chart files ..."
# rm -R ./argo-cd
# echo "Extracting new Helm chart files ..."
# tar -xvzf ./argo-cd-9.0.5.tgz

# echo "Installing Helm chart from local folder ..."
# helm install argo-cd ./argo-cd --namespace argocd --create-namespace --wait -f ./values-custom.yaml

