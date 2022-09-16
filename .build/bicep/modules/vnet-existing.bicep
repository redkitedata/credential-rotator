@description('The Resource Group Name the VNET belongs to.')
param resourceGroupName string

@description('The Subscription ID the VNET belongs to.')
param subscriptionId string

@description('The name of the Virtual Network to be created.')
param virtualNetworkName string

@description('The name of the virtual network subnet to be associated with the Azure Function app.')
param functionSubnetName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: virtualNetworkName
  scope: az.resourceGroup(subscriptionId, resourceGroupName)

  resource functionSubnet 'subnets' existing = {
    name: functionSubnetName
  }
}

output virtualNetworkResourceId string = virtualNetwork.id
output virtualNetworkName string = virtualNetwork.name
output functionSubnetResourceId string = virtualNetwork::functionSubnet.id
