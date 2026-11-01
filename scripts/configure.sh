#!/usr/bin/env bash
# Fills your Azure subscription ID (from "az login") into the project. No arguments needed.
set -euo pipefail
cd "$(dirname "$0")/.."
SUB="$(az account show --query id -o tsv)"
if ! grep -rq "SUBSCRIPTION_ID" --include="*.tf" --include="*.tfvars" .; then
  echo "Subscription already configured. Nothing to do."
  exit 0
fi
find . -type f \( -name "*.tf" -o -name "*.tfvars" \) -exec sed -i "s/SUBSCRIPTION_ID/${SUB}/g" {} +
echo "Configured: Humber ID=8935, owner=robinson.alzatte, subscription=${SUB}"
