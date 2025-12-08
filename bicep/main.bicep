param location string = 'East US'
param resourceGroupName string = 'autopr-rg'
param acrName string = 'autopracr'
param aksClusterName string = 'autopr-aks'

@description('PostgreSQL administrator login username')
param postgresLogin string = 'autopr'

@secure()
param postgresPassword string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: acrName
  location: location
  resourceGroup: rg.name
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
  resourceGroup: rg.name
  properties: {
    dnsPrefix: 'autopr'
    agentPoolProfiles: [
      {
        name: 'default'
        count: 1
        vmSize: 'Standard_DS2_v2'
        mode: 'System'
      }
    ]
    identity: {
      type: 'SystemAssigned'
    }
  }
}

resource postgres 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: 'autopr-postgres'
  location: location
  resourceGroup: rg.name
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
  }
}

resource redis 'Microsoft.Cache/Redis@2020-06-01' = {
  name: 'autopr-redis'
  location: location
  resourceGroup: rg.name
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
