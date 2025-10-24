#!/usr/bin/env bash

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl -n argocd patch cm argocd-cmd-params-cm --type merge --patch-file ./argocd-cmd-params-cm.yaml

