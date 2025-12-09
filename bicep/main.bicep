@description('Legacy infrastructure template - assumes resource group already exists. Deploy at resource group scope: az deployment group create --resource-group <rg-name> --template-file main.bicep')

param location string = 'East US'
param acrName string = 'codeflowacr'
param aksClusterName string = 'codeflow-aks'

@description('PostgreSQL administrator login username')
param postgresLogin string = 'codeflow'

@secure()
param postgresPassword string

resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2022-03-01' = {
  name: aksClusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: 'codeflow'
    agentPoolProfiles: [
      {
        name: 'default'
        count: 1
        vmSize: 'Standard_DS2_v2'
        mode: 'System'
      }
    ]
  }
}

resource postgres 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: 'codeflow-postgres'
  location: location
  sku: {
    name: 'B_Gen5_1'
    tier: 'Basic'
    capacity: 1
  }
  properties: {
    version: '11'
    administratorLogin: postgresLogin
    administratorLoginPassword: postgresPassword
    sslEnforcement: 'Enabled'
    createMode: 'Default'
  }
}

resource redis 'Microsoft.Cache/Redis@2020-06-01' = {
  name: 'codeflow-redis'
  location: location
  properties: {
    sku: {
      name: 'Basic'
      family: 'C'
      capacity: 1
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
  }
}
