@description('Required. The name of the App Service Plan Resorce.')
param name string

@description('Required. The location of the App Service Plan Resorce.')
param location string

@description('Required. The SKU of the App Service Plan.')
param sku object

@description('Required. The kind of the App Service Plan.')
param kind string

@description('Required. Indicates whether the App Service Plan runs on Linux or Windows.')
param isLinux bool

@description('Optional. Any tags to apply to the resource.')
param tags object

resource asp 'Microsoft.Web/serverfarms@2018-02-01' = {
  name: name
  location: location
  sku: sku
  tags: tags
  kind: kind
  properties: {
    reserved: isLinux
  }
}

output id string = asp.id
