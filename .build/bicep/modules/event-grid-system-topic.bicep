@description('Required. The name of the Application Insights Resorce.')
param name string

@description('Required. The location of the Application Insights Resorce.')
param location string

param keyVaultName string

@description('Optional. Any tags to apply to the resource.')
param tags object = {}

var v_Tags = union(tags, { cr_resource: 'eg_system_topic' })

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
}

resource systemTopic 'Microsoft.EventGrid/systemTopics@2021-12-01' = {
  name: name
  location: location
  properties: {
    source: keyVault.id
    topicType: 'microsoft.keyvault.vaults'
  }
  tags: v_Tags
}
