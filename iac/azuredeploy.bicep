@description('The resource location')
param location string = resourceGroup().location

@description('The VM admin username')
param adminUsername string

@secure()
@description('The VM admin password')
param adminPassword string

@description('The VM size')
@allowed([
  'Standard_D1'
])
param vmSize string = 'Standard_D1'

resource cmsstorage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: toLower('cmsstorage')
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  tags: {
    displayName: 'cms Storage Account'
  }
  properties: {
    accessTier: 'Hot'
  }
}

resource cms_PublicIP 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: 'cms-PublicIP'
  location: location
  tags: {
    displayName: 'PublicIPAddress'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower('cms')
    }
  }
}

resource cms_VirtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: 'cms-VirtualNetwork'
  location: location
  tags: {
    displayName: 'cms-VirtualNetwork'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'cms-VirtualNetwork-Subnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

resource cms_NetworkInterface 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: 'cms-NetworkInterface'
  location: location
  tags: {
    displayName: 'cms-NetworkInterface'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: cms_PublicIP.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'cms-VirtualNetwork', 'cms-VirtualNetwork-Subnet')
          }
        }
      }
    ]
  }
  dependsOn: [

    cms_VirtualNetwork
  ]
}

resource cms 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: 'cms'
  location: location
  tags: {
    displayName: 'cms'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'cms'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '22.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: 'cms-OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: cms_NetworkInterface.id
        }
      ]
    }
  }
  dependsOn: [
    cmsstorage

  ]
}
