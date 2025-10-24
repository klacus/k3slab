#!/usr/bin/env bash

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# We terminate the TLS at the gateway, so the ArgoCD service can be run in insecure mode.
kubectl -n argocd patch cm argocd-cmd-params-cm --type merge --patch-file ./argocd-cmd-params-cm.yaml

