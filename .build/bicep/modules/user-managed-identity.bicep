param name string

param location string

@description('Optional. Any tags to apply to the resource.')
param tags object = {}

var v_Tags = union(tags, { cr_resource: 'umi' })

resource umi 'Microsoft.ManagedIdentity/userAssignedIdentities@2021-09-30-preview' = {
  name: name
  location: location
  tags: v_Tags
}

output principalId string = umi.properties.principalId
output resourceId string = umi.id
