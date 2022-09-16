@description('Required. The name of the Storage Account Resorce.')
param name string

@description('Required. The location of the Storage Account Resorce.')
param location string

@description('Optional. Any tags to apply to the resource.')
param tags object

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  identity: {
    type: 'SystemAssigned'
  }

  resource storageAccountTableService 'tableServices@2021-09-01' = {
    name: 'default'

    resource storageAccountTableCredentialMetastore 'tables@2021-09-01' = {
      name: 'CredentialMetastore'
    }
  }
}

output id string = storageAccount.id
output name string = storageAccount.name
output apiVersion string = storageAccount.apiVersion
