@description('Required. The name of the Key Vault Resorce.')
param name string

@description('Required. The location of the Key Vault Resorce.')
param location string

@description('Required. The Azure Tenant ID.')
param tenantId string

@description('Optional. Any tags to apply to the resource.')
param tags object

var v_Tags = union(tags, { cr_resource: 'key_vault' })

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: name
  location: location
  tags: v_Tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    enableRbacAuthorization: true
  }
}

output id string = keyVault.id
output name string = keyVault.name
