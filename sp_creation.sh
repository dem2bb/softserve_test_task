#! /bin/bash
set -e

SP_NAME="eschool-sp"
SUBSCRIPTION_ID="38201a58-67d5-4800-940c-3aff3caa9451"

az login
az account set --subscription "$SUBSCRIPTION_ID"

az ad sp create-for-rbac \
   --name "$SP_NAME" \
   --role "Contributor" \
   --scopes "/subscriptions/$SUBSCRIPTION_ID"