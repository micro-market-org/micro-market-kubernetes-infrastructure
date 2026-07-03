#!/bin/bash

export GOOGLE_APPLICATION_CREDENTIALS="../i-binder-461513-v8-40884e000270.json"

export USE_GKE_GCLOUD_AUTH_PLUGIN=True

gcloud container clusters get-credentials gke-microservices1691715-dev --region=europe-central2-a --project=i-binder-461513-v8

kubectl config set-credentials gke_i-binder-461513-v8_europe-central2_gke-microservices1691715-dev \
  --exec-command=gke-gcloud-auth-plugin \
  --exec-api-version=client.authentication.k8s.io/v1beta1

terraform init -backend-config="bucket=terraformmicroservicesstate" \
  -backend-config="prefix=kubernetes/state" \
  -backend-config="credentials=../i-binder-461513-v8-40884e000270.json"

terraform apply --var-file=./tfvars_files/dev.tfvars \
  --var cloud_provider="gcp" \
  --var gcp_project="i-binder-461513-v8" \
  --var gcp_region="europe-central2" \
  --var gcp_zone="europe-central2-a" \
  --var gcp_credentials="../i-binder-461513-v8-40884e000270.json"
