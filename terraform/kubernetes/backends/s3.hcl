region       = "eu-central-1"
use_lockfile = true
encrypt      = true
# bucket and key are passed on the command line so they stay account-ID-agnostic:
#   -backend-config="bucket=terraform-state-<account-id>-eu-central-1"
#   -backend-config="key=kubernetes/aws/<env>/terraform.tfstate"
