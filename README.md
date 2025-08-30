# Az-TF-deploy1
# 🚀 Azure Service Principal Setup for Terraform (with Troubleshooting Story)

While setting up Terraform to provision Azure resources with below bash script, I faced an interesting challenge with **jq** installation on WSL.  
This repo documents the **problem, troubleshooting steps, and the working solution**.

Script with jq (JSON parser) - which caused the issue***
#!/bin/bash

# ==============================
# CONFIGURATION - EDIT THESE
# ==============================
SUBSCRIPTION_ID="<YOUR_SUBSCRIPTION_ID>"
RESOURCE_GROUP="rg-demo"         # must match your TF config
LOCATION="eastus"                # cheapest for free tier usually
SP_NAME="terraform-sp"

# ==============================
# 1. Login to Azure
# ==============================
echo "Logging into Azure..."
az login --only-show-errors

# Set the subscription
az account set --subscription "$SUBSCRIPTION_ID"

# ==============================
# 2. Create Resource Group
# ==============================
echo "Creating resource group: $RESOURCE_GROUP in $LOCATION..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION"

# ==============================
# 3. Create Service Principal
# ==============================
echo "Creating service principal: $SP_NAME..."
SP_OUTPUT=$(az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
  --sdk-auth)

# ==============================
# 4. Assign Key Vault Role for Secrets
# ==============================
echo "Assigning Key Vault Secrets Officer role..."
SP_APP_ID=$(echo $SP_OUTPUT | jq -r '.clientId')
az role assignment create \
  --assignee "$SP_APP_ID" \
  --role "Key Vault Secrets Officer" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"

# ==============================
# 5. Output credentials to a file
# ==============================
echo "Saving Service Principal credentials to azure-sp.json..."
echo $SP_OUTPUT > azure-sp.json

echo "=============================="
echo "Service Principal created successfully!"
echo "Credentials saved in: azure-sp.json"
echo "Export the following before running Terraform:"
echo ""
echo "export ARM_CLIENT_ID=$(jq -r '.clientId' azure-sp.json)"
echo "export ARM_CLIENT_SECRET=$(jq -r '.clientSecret' azure-sp.json)"
echo "export ARM_SUBSCRIPTION_ID=$(jq -r '.subscriptionId' azure-sp.json)"
echo "export ARM_TENANT_ID=$(jq -r '.tenantId' azure-sp.json)"
echo ""
echo "=============================="


>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

## ⚡ The Problem
- I had a Bash script that automated:
  1. Creating a Resource Group
  2. Creating a Service Principal
  3. Assigning required roles at Resource Group scope
  4. Exporting credentials for Terraform

- The script used `jq` to parse JSON output.  
- But on my Windows machine (using VS Code + WSL), `jq` was **not installed** and `sudo` wasn’t enabled, leading to errors like:

```bash
./setup-terraform-sp.sh: line 42: jq: command not found
unrecognized arguments:

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

🔍 The Investigation

Tried sudo apt install jq → Blocked due to sudo restrictions in WSL.

Considered alternative JSON parsers → felt overkill.

Realized I could remove jq entirely and still extract required values directly from az ad sp create-for-rbac output.


>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

✅ The Solution

Rewrote the script without jq.

Used Azure CLI’s --query and --output tsv/json options to fetch values.

Script now:

Creates RG

Creates SP

Assigns Key Vault role

Outputs credentials into azure-sp.json

Working script: setup-terraform-sp.sh

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

🛠️ Usage
# Login to Azure
az login

# Run script
./setup-terraform-sp.sh (after creation of the .sh don't forget to change the access with -- "chmod +x <that .sh file> Enter" command) 😊
  

