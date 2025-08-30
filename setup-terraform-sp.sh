#!/bin/bash

# ==============================
# CONFIGURATION (edit these)
# ==============================
SUBSCRIPTION_ID=<"your az subscription id">
RESOURCE_GROUP=<"rg name">
LOCATION=<location name">
SP_NAME=<"Service principal">

# ==============================
# 1. Login and set subscription
# ==============================
echo "Logging into Azure..."
az login --only-show-errors
az account set --subscription "$SUBSCRIPTION_ID"

# ==============================
# 2. Create Resource Group
# ==============================
echo "Creating resource group: $RESOURCE_GROUP in $LOCATION..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output none

# ==============================
# 3. Create Service Principal
# ==============================
echo "Creating service principal: $SP_NAME..."
SP_OUTPUT=$(az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP")

# Extract values (without jq)
CLIENT_ID=$(echo $SP_OUTPUT | grep -oP '(?<="appId": ")[^"]*')
CLIENT_SECRET=$(echo $SP_OUTPUT | grep -oP '(?<="password": ")[^"]*')
TENANT_ID=$(echo $SP_OUTPUT | grep -oP '(?<="tenant": ")[^"]*')

# ==============================
# 4. Show results
# ==============================
echo "=============================="
echo "Resource Group: $RESOURCE_GROUP"
echo "Service Principal: $SP_NAME"
echo "Client ID: $CLIENT_ID"
echo "Client Secret: $CLIENT_SECRET"
echo "Tenant ID: $TENANT_ID"
echo "Subscription ID: $SUBSCRIPTION_ID"
echo "=============================="

# Optionally save to file
cat > azure-sp.json <<EOL
{
  "clientId": "$CLIENT_ID",
  "clientSecret": "$CLIENT_SECRET",
  "subscriptionId": "$SUBSCRIPTION_ID",
  "tenantId": "$TENANT_ID"
}
EOL

echo "Credentials saved to azure-sp.json"
