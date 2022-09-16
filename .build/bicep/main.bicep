// Parameters
// -  Required
@minLength(1)
@maxLength(8)
@description('Required. Environment name used as part of automatic resource naming when resource names are not provided. Refer to Bicep variables section for usage.')
param environmentSuffixName string

@minLength(1)
@maxLength(10)
@description('Required. Base name used as part of automatic resource naming when resource names are not provided. Refer to Bicep variables section for usage.')
param resourceBaseName string

@description('Required. The API Key used by Send Grid to send alerts oout by email when a new secret version is created.')
param sendgridApiKey string

@description('Required. The Client ID of the Service Principals Application Registration.')
param servicePrincipalApplicationRegistrationClientID string

@secure()
@description('Required. The Client Secret of the Service Principals Application Registration.')
param servicePrincipalApplicationRegistrationClientSecret string

@description('Required. The Object ID of the Service Principals Enterprise Application.')
param servicePrincipalEnterpriseApplicationObjectID string

// -  Optional
@description('Optional. The name of the Application Insights Instance to create. If no name is provided, one will be generated based on Azure naming recommendations.')
param appInsightsName string = ''

@description('Optional. Indicates whether the Service Principal has permissions to assign RBAC roles. If not, role assignment must be handled separately.')
param canAssignRbacRoles bool = true

@description('Optional. ID of the resource group containing the existing VNET when shouldUseExistingVnet is set to true. Defaults to deployment target resource group.')
param existingVirtualNetworkResourceGroupName string = resourceGroup().name

@description('Optional. ID of the subscription containing the existing VNET when shouldUseExistingVnet is set to true. Defaults to deployment target subscription.')
param existingVirtualNetworkSubscriptionID string = subscription().id

@description('Optional. The name of the Function App to create. If no name is provided, one will be generated based on Azure naming recommendations.')
param functionAppName string = ''

@description('Optional. The name of the Function App(s) App Service Plan to create. If no name is provided, one will be generated based on Azure naming recommendations.')
param functionAppServicePlanName string = ''

@description('Optional. The IP address space used for the Azure Function integration subnet when shouldUseExistingVnet is set to false.')
param functionSubnetAddressPrefix string = '10.0.0.0/24'

@description('Optional. The name of the virtual network subnet to be associated with the Azure Function app.')
param functionSubnetName string = 'snet-func'

@description('Optional. The name of the Key Vault to create. If no name is provided, one will be generated based on Azure naming recommendations.')
param keyVaultName string = ''

@description('Optional. The location into which the resources should be deployed.')
param location string = resourceGroup().location

@description('Optional. Indicates whether or not to enable VNET integration. Defaults to false.')
param shouldEnableVnetIntegration bool = false

@description('Optional. Indicates whether or not to integrate with an existing VNET. Must be used in conjunction with shouldEnableVnetIntegration being set to true. Defaults to false.')
param shouldUseExistingVnet bool = false

@description('Optional. The name of the Storage Account to create. If no name is provided, one will be generated based on Azure naming recommendations.')
param storageAccountName string = ''

@description('Optional. Generic tags to apply to all resources.')
param tags object = {}

@description('Optional. The address space of the VNET when a new VNET is created.')
param virtualNetworkAddressPrefixes array = [
  '10.0.0.0/16'
]

@description('Optional. Name of the VNET being used by the function app. The value is only used when shouldEnableVnetIntegration is set to true, and refers to either an existing VNET name or is used as a new name depending on the setting of shouldUseExistingVnet.')
param vnetName string = ''

@description('Required. The sender of the Key Vault Secret Update email alert. This should map to the email used in the SendGrid setup.')
param emailAlertSender string

@description('Required. The recipients of the Key Vault Secret Update email alert. Where multiple emails are required please separate with a semicolon.')
param emailAlertRecipients string

// Variables
// -  Abbreviations
var abbrStorageAccount = 'st'
var abbrEventGridTopic = 'evgt-'
var abbrFunctionApp = 'func-'
var abbrKeyVault = 'kv-'
var abbrApplicationInsights = 'appi-'
var abbrAppServicePlan = 'asp-'
var abbrVirtualNetwork = 'vnet-'
var abbrVirtualNetworkSubnet = 'snet-'
var abbrUserManagedIdentity = 'umi-'
var abbrMetaSecret = 'metacr-'

// -  Misc.
var resourceBaseNameLower = toLower(resourceBaseName)
var resourceSuffix = '${resourceBaseNameLower}-${environmentSuffixName}-001'
var resourceSuffixSafe = '${resourceBaseNameLower}${environmentSuffixName}001'

// -  Resource Names
var v_AppInsightsName = appInsightsName == '' ? '${abbrApplicationInsights}${resourceSuffix}' : appInsightsName
var v_EventGridTopicName = '${abbrEventGridTopic}${resourceBaseNameLower}'
var v_FunctionAppName = functionAppName == '' ? '${abbrFunctionApp}${resourceSuffix}' : functionAppName
var v_FunctionAppServicePlanName = functionAppServicePlanName == '' ? '${abbrAppServicePlan}${v_FunctionAppName}' : functionAppServicePlanName
var v_FunctionSubnetName = functionSubnetName == '' ? '${abbrVirtualNetworkSubnet}func' : functionSubnetName
var v_KeyVaultName = keyVaultName == '' ? '${abbrKeyVault}${resourceSuffix}' : keyVaultName
var v_KeyVaultSecretClientIDName = '${abbrMetaSecret}${resourceBaseNameLower}-client-id'
var v_KeyVaultSecretClientSecretName = '${abbrMetaSecret}${resourceBaseNameLower}-client-secret'
var v_KeyVaultSecretSendgridApiKeyName = '${abbrMetaSecret}${resourceBaseNameLower}-sendgrid-api-key'
var v_StorageAccountName = storageAccountName == '' ? '${abbrStorageAccount}${resourceSuffixSafe}' : storageAccountName
var v_UserManagedIdentityName = '${abbrUserManagedIdentity}${resourceSuffix}'
var v_VnetName = vnetName == '' ? '${abbrVirtualNetwork}${resourceSuffix}' : vnetName

// -  RBAC Roles (Well Known IDs)
var adRoleStorageTableDataContributor = subscriptionResourceId('Microsoft.Authorization/RoleDefinitions', '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3')
var adRoleKeyVaultSecretsOfficer = subscriptionResourceId('Microsoft.Authorization/RoleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
var adRoleKeyVaultSecretsUser = subscriptionResourceId('Microsoft.Authorization/RoleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

// Resources
module existingVirtualNetwork './modules/vnet-existing.bicep' = if (shouldEnableVnetIntegration && shouldUseExistingVnet) {
  name: 'ext-${v_VnetName}'
  params: {
    resourceGroupName: existingVirtualNetworkResourceGroupName
    subscriptionId: existingVirtualNetworkSubscriptionID
    virtualNetworkName: v_VnetName
    functionSubnetName: v_FunctionSubnetName
  }
}

module newVirtualNetwork './modules/vnet-new.bicep' = if (shouldEnableVnetIntegration && !shouldUseExistingVnet) {
  name: 'new-${v_VnetName}'
  params: {
    virtualNetworkName: v_VnetName
    functionSubnetName: v_FunctionSubnetName
    functionSubnetAddressPrefix: functionSubnetAddressPrefix
    virtualNetworkAddressPrefixes: virtualNetworkAddressPrefixes
    location: location
    tags: tags
  }
}

var outFunctionSubnetResourceId = shouldEnableVnetIntegration ? (shouldUseExistingVnet ? existingVirtualNetwork.outputs.functionSubnetResourceId : newVirtualNetwork.outputs.functionSubnetResourceId) : ''

module appInsights 'modules/app-insights.bicep' = {
  name: v_AppInsightsName
  params: {
    name: v_AppInsightsName
    location: location
    tags: tags
  }
}

module storageAccount 'modules/storage-account.bicep' = {
  name: v_StorageAccountName
  params: {
    name: v_StorageAccountName
    location: location
    tags: tags
  }
}

module keyVault 'modules/key-vault.bicep' = {
  name: v_KeyVaultName
  params: {
    name: v_KeyVaultName
    location: location
    tags: tags
    tenantId: subscription().tenantId
  }
}

module keyVaultSecretClientID 'modules/key-vault-secret.bicep' = {
  name: v_KeyVaultSecretClientIDName
  params: {
    keyVaultName: keyVault.name
    secretName: v_KeyVaultSecretClientIDName
    secretValue: servicePrincipalApplicationRegistrationClientID
    tags: { cr_resource: 'sp_clientid' }
  }
}

module keyVaultSecretClientSecret 'modules/key-vault-secret.bicep' = {
  name: v_KeyVaultSecretClientSecretName
  params: {
    keyVaultName: keyVault.name
    secretName: v_KeyVaultSecretClientSecretName
    secretValue: servicePrincipalApplicationRegistrationClientSecret
    tags: { cr_resource: 'sp_clientsecret' }
  }
}

module keyVaultSecretSendgridApiKey 'modules/key-vault-secret.bicep' = {
  name: v_KeyVaultSecretSendgridApiKeyName
  params: {
    keyVaultName: keyVault.name
    secretName: v_KeyVaultSecretSendgridApiKeyName
    secretValue: sendgridApiKey
    tags: { cr_resource: 'sendgrid_api_key' }
  }
}

var funcAspConfig = loadJsonContent('json/app-service-plan.config.json', 'functionapp')

module funcAppServicePlan 'modules/app-service-plan.bicep' = {
  name: v_FunctionAppServicePlanName
  params: {
    name: v_FunctionAppServicePlanName
    location: location
    sku: funcAspConfig.sku
    kind: funcAspConfig.kind
    isLinux: funcAspConfig.properties.reserved
    tags: tags
  }
}

module functionApp 'modules/function-app.bicep' = {
  name: v_FunctionAppName
  params: {
    appInsightsName: appInsights.name
    appServicePlanName: funcAppServicePlan.name
    keyVaultName: keyVault.name
    keyVaultSecretClientIdName: v_KeyVaultSecretClientIDName
    keyVaultSecretClientSecretName: v_KeyVaultSecretClientSecretName
    keyVaultSecretSendgridApiKeyName: v_KeyVaultSecretSendgridApiKeyName
    location: location
    name: v_FunctionAppName
    storageAccountName: storageAccount.name
    tags: tags
    subnetResourceId: outFunctionSubnetResourceId
    userManagedIdentityResourceId: umi.outputs.resourceId
    emailAlertSender: emailAlertSender
    emailAlertRecipients: emailAlertRecipients
  }
}

module umi 'modules/user-managed-identity.bicep' = {
  name: v_UserManagedIdentityName
  params: {
    name: v_UserManagedIdentityName
    location: location
    tags: tags
  }
}

module roleAssignmentStorageAccountServicePrincipal 'modules/role-assignment-storage-account.bicep' = if (canAssignRbacRoles) {
  name: guid(storageAccount.name, servicePrincipalEnterpriseApplicationObjectID, adRoleStorageTableDataContributor)
  params: {
    principalId: servicePrincipalEnterpriseApplicationObjectID
    roleDefinitionId: adRoleStorageTableDataContributor
    storageAccountName: storageAccount.outputs.name
  }
}

module roleAssignmentKeyVaultServicePrincipal 'modules/role-assignment-key-vault.bicep' = if (canAssignRbacRoles) {
  name: guid(keyVault.name, servicePrincipalEnterpriseApplicationObjectID, adRoleKeyVaultSecretsOfficer)
  params: {
    principalId: servicePrincipalEnterpriseApplicationObjectID
    roleDefinitionId: adRoleKeyVaultSecretsOfficer
    keyVaultName: keyVault.name
  }
}

module roleAssignmentKeyVaultUserManagedIdentity 'modules/role-assignment-key-vault.bicep' = if (canAssignRbacRoles) {
  name: guid(keyVault.name, umi.name, adRoleKeyVaultSecretsUser)
  params: {
    principalId: umi.outputs.principalId
    roleDefinitionId: adRoleKeyVaultSecretsUser
    keyVaultName: keyVault.name
  }
}

module systemTopic 'modules/event-grid-system-topic.bicep' = {
  name: v_EventGridTopicName
  params: {
    name: v_EventGridTopicName
    keyVaultName: keyVault.outputs.name
    location: location
  }
}
