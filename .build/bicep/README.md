# Creating Resources via Bicep

## Overview

This project uses Azure Bicep to deploy infrastructure as code.

The Bicep supports three main deployment scenarios for the Credential Rotator application:

- No VNET: The application is deployed without any VNET integration.
- New VNET: Alongside the deployment of the core infrastructure, additional networking resources (VNET + Subnets) are created to enable self contained VNET integration. Both core and networking resources are deployed to the same ResourceGroup.
- Existing VNET: The application is deployed referencing existing networking infrastructure - it is not a requirement that existing networks live in the resource group where core infrastructure will be deployed.

This README provides example configurations that can be used to setup the Credential Rotator for each of these scenarios below. These configurations are considered the minimum requirements for deployment - please review the parameter descriptions in [main.bicep](./main.bicep) for further extensibility.

## Resource Naming

For simplicity, the Bicep in this project will automatically generate resource names for you unless otherwise specified.

Automatic resource naming is determined via the resource type (predefined), the resource base name (provided by user), and environment suffix name (provided by user) and is designed to follow Azure best practice where possible.

Please review the naming conventions below to understand how your resources would be created:

> The examples below assume the following parameters were provided: `environmentSuffixName = 'dev'`, and `resourceBaseName = 'cred'`

| Resource | Generated Name | Can be Overwritten |
| ----------- | ----------- | ----------- |
| Application Insights | appi-cred-dev-001 | :heavy_check_mark: |
| Event Grid Topic | evgt-cred | :x: |
| Function App | func-cred-dev-001 | :heavy_check_mark: |
| Function App Service Plan | asp-func-cred-dev-001 | :heavy_check_mark: |
| Function Subnet | snet-func | :heavy_check_mark: |
| Key Vault | kv-cred-dev-001 | :heavy_check_mark: |
| Key Vault Secret - Client ID | secret-cred-client-id | :heavy_check_mark: |
| Key Vault Secret - Client Secret | secret-cred-client-secret | :heavy_check_mark: |
| Storage Account | stcreddev001 | :heavy_check_mark: |
| Virtual Network | vnet-cred-dev-001 | :heavy_check_mark: |

## Example Configurations

### No VNET Intergation

``` jsonc
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environmentSuffixName": {
      "value": "dev" // Environment name used when creating Azure Resources when no other name is provided. E.g. dev, test, nonprod, prod etc.
    },
    "resourceBaseName": {
      "value": "cred" // Common name used when creating Azure Resources when no other name is provided.
    },
    "servicePrincipalApplicationRegistrationClientID": {
      "value": "***" // Pulled from Azure DevOps Library
    },
    "servicePrincipalApplicationRegistrationClientSecret": {
      "value": "***" // Pulled from Azure DevOps Library
    },
    "servicePrincipalEnterpriseApplicationObjectID": {
      "value": "***" // Pulled from Azure DevOps Library
    },
    "shouldEnableVnetIntegration": {
      "value": false
    },
    "shouldUseExistingVnet": {
      "value": false
    }
  }
}
```

### Integrate with New VNET

``` jsonc
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environmentSuffixName": {
      "value": "dev" // Environment name used when creating Azure Resources when no other name is provided. E.g. dev, test, nonprod, prod etc.
    },
    "functionSubnetAddressPrefix": {
      "value": "10.0.0.0/24"
    },
    "resourceBaseName": {
      "value": "cred" // Common name used when creating Azure Resources when no other name is provided.
    },
    "servicePrincipalApplicationRegistrationClientID": {
      "value": "***" // Pulled from Azure DevOps Library
    },
    "servicePrincipalApplicationRegistrationClientSecret": {
      "value": "***" // Pulled from Azure DevOps Library
    },
    "servicePrincipalEnterpriseApplicationObjectID": {
      "value": "***" // Pulled from Azure DevOps Library
    },
    "shouldEnableVnetIntegration": {
      "value": true
    },
    "shouldUseExistingVnet": {
      "value": false
    },
    "virtualNetworkAddressPrefixes": {
      "value": [
        "10.0.0.0/16"
      ]
    }
  }
}
```

### Integrate with Existing VNET

``` jsonc
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environmentSuffixName": {
      "value": "dev" // Environment name used when creating Azure Resources when no other name is provided. E.g. dev, test, nonprod, prod etc.
    },
    "existingVirtualNetworkResourceGroupName": {
      "value": "" // Name of the Resource Group which contains the existing VNET.
    },
    "existingVirtualNetworkSubscriptionID": {
      "value": "" // ID of the Subscription which contains the existing VNET.
    },
    "resourceBaseName": {
      "value": "cred" // Common name used when creating Azure Resources when no other name is provided.
    },
    "servicePrincipalApplicationRegistrationClientID": {
      "value": "***" // Pulled from Azure DevOps Library
    },
    "servicePrincipalApplicationRegistrationClientSecret": {
      "value": "***" // Pulled from Azure DevOps Library
    },
    "servicePrincipalEnterpriseApplicationObjectID": {
      "value": "***" // Pulled from Azure DevOps Library
    },
    "shouldEnableVnetIntegration": {
      "value": true
    },
    "shouldUseExistingVnet": {
      "value": true
    },
    "vnetName": {
      "value": "" // The name of the existing VNET.
    },
  }
}
```
