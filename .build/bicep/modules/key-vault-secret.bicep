param keyVaultName string

param secretName string

@secure()
param secretValue string

param tags object = {}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
}

resource keyVaultSecretClientID 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: keyVault
  name: secretName
  tags: tags
  properties: {
    value: secretValue
  }
}
