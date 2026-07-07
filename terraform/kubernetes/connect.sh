#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../../.env"

if [[ -f "${ENV_FILE}" ]]; then
  set -o allexport
  # shellcheck source=/dev/null
  source "${ENV_FILE}"
  set +o allexport
fi

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command aws
require_command kubectl

ENVIRONMENT="${ENVIRONMENT:-dev}"
PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"
AWS_REGION="${AWS_REGION:-eu-central-1}"
CLUSTER_NAME="${EKS_CLUSTER_NAME:-eks-${PROJECT_NAMESPACE}-${ENVIRONMENT}}"

if [[ ! "${ENVIRONMENT}" =~ ^(dev|staging|prod)$ ]]; then
  echo "Unsupported ENVIRONMENT '${ENVIRONMENT}'. Use dev, staging, or prod." >&2
  exit 1
fi

AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
AWS_ARN="$(aws sts get-caller-identity --query Arn --output text)"
CONTEXT_ALIAS="${KUBE_CONTEXT_ALIAS:-${PROJECT_NAMESPACE}-${ENVIRONMENT}-aws-${AWS_ACCOUNT_ID}}"

echo "AWS account: ${AWS_ACCOUNT_ID}"
echo "AWS identity: ${AWS_ARN}"
echo "Region: ${AWS_REGION}"
echo "Environment: ${ENVIRONMENT}"
echo "Cluster: ${CLUSTER_NAME}"
echo "Context alias: ${CONTEXT_ALIAS}"

aws eks describe-cluster \
  --region "${AWS_REGION}" \
  --name "${CLUSTER_NAME}" \
  --query "cluster.status" \
  --output text >/dev/null

aws eks update-kubeconfig \
  --region "${AWS_REGION}" \
  --name "${CLUSTER_NAME}" \
  --alias "${CONTEXT_ALIAS}"

kubectl config use-context "${CONTEXT_ALIAS}" >/dev/null
kubectl cluster-info

echo
echo "Connected kubectl context '${CONTEXT_ALIAS}'."
echo "Lens can now import/use this context from your kubeconfig."
