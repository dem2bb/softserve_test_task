# Test task step by step realization guide

## Step 1. Azure account and CLI

Created a free Azure account and logged in through the CLI:

```bash
az login
az account show
```

## Step 2. Service principal

Script `sp_creation.sh` creates the SP and assigns the Contributor role
to the subscription.

The output (appId, password, tenant) is stored locally in `.env` and
loaded as `ARM_*` environment variables. `.env` is gitignored.

## Step 3. Infrastructure (using Terraform)

Two Ubuntu 22.04 VMs, size B2s, port 22 open for SSH.

Files:
1. `providers.tf` — azurerm provider, reads credentials from `ARM_*` env vars
2. `variables.tf` — prefix, location, VM size, admin user, VM count
3. `main.tf` — resource group, vnet, subnet, NSG, public IPs, NICs, NSG associations, the VMs
4. `outputs.tf` — public IPs of both VMs

```bash
terraform init
terraform plan
terraform apply
```

After apply, the VM public IPs come from the outputs. SSH in with:

```bash
ssh -i ~/.ssh/eschool_azure eschool@VM-IP
```

## Step 4. Prepare VM1

Installed Git, Java and Maven:

```bash
sudo apt update
sudo apt install git -y
sudo apt install openjdk-8-jdk -y
sudo apt install maven -y
```

Cloned the eSchool repo into the home directory:

```bash
git clone https://github.com/yurkovskiy/eSchool
```