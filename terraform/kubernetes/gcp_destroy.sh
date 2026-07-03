#!/bin/bash

export GOOGLE_APPLICATION_CREDENTIALS="../i-binder-461513-v8-40884e000270.json"

export USE_GKE_GCLOUD_AUTH_PLUGIN=True

terraform init -reconfigure -backend-config="bucket=terraformmicroservicesstate" \
  -backend-config="prefix=terraform/state" \
  -backend-config="credentials=../i-binder-461513-v8-40884e000270.json"

terraform destroy --var-file=./tfvars_files/dev.tfvars \
  --var cloud_provider="gcp" \
  --var gcp_project="i-binder-461513-v8" \
  --var gcp_region="europe-central2" \
  --var gcp_zone="europe-central2-a" \
  --var gcp_credentials="../i-binder-461513-v8-40884e000270.json"
# terraform force-unlock <LOCK_ID>
