#!/bin/bash

kubectl apply -f ./configs/production_issuer.yaml
kubectl apply -f ./configs/argocd_network_policies.yaml
kubectl apply -f ./configs/prometheus_recording_rules.yaml
kubectl apply -f ./configs/prometheus_alerting_rules.yaml
kubectl apply -f ./configs/argocd_project.yaml
kubectl apply -f ./configs/argocd_application.yaml

WORKSPACE="prod"
CI_PROJECT_NAMESPACE="danielgherasim-microservices"
PUBLIC_IP_NAME=$(az network public-ip list --resource-group rg-$CI_PROJECT_NAMESPACE-$WORKSPACE-aks --query "[?contains(name, 'kubernetes-')].name" -o tsv)
az network public-ip update --resource-group rg-$CI_PROJECT_NAMESPACE-$WORKSPACE-aks --name $PUBLIC_IP_NAME --dns-name $CI_PROJECT_NAMESPACE