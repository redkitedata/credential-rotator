@description('Required. The name of the Application Insights Resorce.')
param name string

@description('Required. The location of the Application Insights Resorce.')
param location string

@description('Required. The name of the Application Insights workspace.')
param appInsightsName string

@description('Required. The name of the Key Vault that contains the Service Principal the Function App runs off.')
param keyVaultName string

@description('Required. The name of the secret in Key Vault that contains the Service Principal Client ID.')
param keyVaultSecretClientIdName string

@description('Required. The name of the secret in Key Vault that contains the Service Principal Client Secret.')
param keyVaultSecretClientSecretName string

@description('Required. The name of the secret in Key Vault that contains the Sendgrid API Key.')
param keyVaultSecretSendgridApiKeyName string

@description('Required. The name of the App Service Plan the Function App runs off.')
param appServicePlanName string

@description('Required. The sender of the Key Vault Secret Update email alert. This should map to the email used in the SendGrid setup.')
param emailAlertSender string

@description('Required. The recipients of the Key Vault Secret Update email alert. Where multiple emails are required please separate with a semicolon.')
param emailAlertRecipients string

@description('Required. The name of the Storage Account used by the Function App.')
param storageAccountName string

@description('Optional. The Resource ID of the subnet the Function App is connected to if VNET integration is required.')
param subnetResourceId string = ''

@description('Required. The User Managed Identity Resource ID the Function App will inherit.')
param userManagedIdentityResourceId string

@description('Optional. Any tags to apply to the resource.')
param tags object

var v_Tags = union(tags, { cr_resource: 'function_app' })

resource asp 'Microsoft.Web/serverfarms@2018-02-01' existing = {
  name: appServicePlanName
}

resource appInsights 'microsoft.insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName

  resource keyVaultSecretClientID 'secrets@2021-11-01-preview' existing = {
    name: keyVaultSecretClientIdName
  }

  resource keyVaultSecretClientSecret 'secrets@2021-11-01-preview' existing = {
    name: keyVaultSecretClientSecretName
  }

  resource keyVaultSecretSendgridApiKey 'secrets@2021-11-01-preview' existing = {
    name: keyVaultSecretSendgridApiKeyName
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: name
  location: location
  tags: v_Tags
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userManagedIdentityResourceId}': {}
    }
  }
  properties: {
    serverFarmId: asp.id
    reserved: true
    httpsOnly: true
    keyVaultReferenceIdentity: userManagedIdentityResourceId
    virtualNetworkSubnetId: subnetResourceId == '' ? null : subnetResourceId
    siteConfig: {
      linuxFxVersion: 'Python|3.9'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        }
        {
          name: 'AZURE_CLIENT_ID'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${keyVault::keyVaultSecretClientID.name})'
        }
        {
          name: 'AZURE_CLIENT_SECRET'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${keyVault::keyVaultSecretClientSecret.name})'
        }
        {
          name: 'AZURE_TENANT_ID'
          value: tenant().tenantId
        }
        {
          name: 'AZURE_TABLE_STORAGE_ENDPOINT'
          value: 'https://${storageAccount.name}.table.${environment().suffixes.storage}/'
        }
        {
          name: 'CREDENTIAL_ROTATOR_METASTORE_TABLE_NAME'
          value: 'CredentialMetastore'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'SENDGRID_API_KEY'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${keyVault::keyVaultSecretSendgridApiKey.name})'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'ENABLE_ORYX_BUILD'
          value: 'true'
        }
        {
          name: 'FROM_EMAIL'
          value: emailAlertSender
        }
        {
          name: 'RECIPIENTS'
          value: emailAlertRecipients
        }
      ]
    }
  }
}
