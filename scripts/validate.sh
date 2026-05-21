#!/usr/bin/env bash
set -euo pipefail

echo "Running Terraform module validation..."

terraform fmt -check -recursive
terraform init -backend=false
terraform validate

