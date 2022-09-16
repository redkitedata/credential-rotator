@description('The name of the Virtual Network to be created.')
param virtualNetworkName string

@description('The IP adddress space used for the virtual network.')
param virtualNetworkAddressPrefixes array = [
  '10.0.0.0/16'
]

@description('The name of the virtual network subnet to be associated with the Azure Function app.')
param functionSubnetName string = 'snet-func'

@description('The IP address space used for the Azure Function integration subnet.')
param functionSubnetAddressPrefix string = '10.0.0.0/24'

param location string = resourceGroup().location

@description('Optional. Any tags to apply to the resource.')
param tags object

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: virtualNetworkAddressPrefixes
    }
    subnets: [
      {
        name: functionSubnetName
        properties: {
          addressPrefix: functionSubnetAddressPrefix
          delegations: [
            {
              name: 'snet-del-func'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
  tags: tags
}

output virtualNetworkResourceId string = virtualNetwork.id
output virtualNetworkName string = virtualNetwork.name
output functionSubnetResourceId string = resourceId('Microsoft.Network/VirtualNetworks/subnets', virtualNetwork.name, functionSubnetName)
