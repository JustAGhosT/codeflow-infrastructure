@description('Environment name (prod, dev, staging)')
param environment string = 'prod'

@description('Azure region abbreviation (eus, wus, san, etc.)')
param regionAbbr string = 'san'

@description('Azure region full name for most resources')
param location string = 'eastus2'

@description('PostgreSQL region (must support Flexible Server and be available in your subscription)')
param postgresLocation string = 'southafricanorth'

@description('Container image name. Must be publicly accessible or use registry credentials. Build and push the image first using the GitHub Actions workflow. Default is a placeholder for testing.')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('PostgreSQL administrator login username')
param postgresLogin string = 'codeflow'

@secure()
@description('PostgreSQL administrator password')
param postgresPassword string

@secure()
@description('Redis password')
param redisPassword string

@description('Custom domain name for the container app. Leave empty to skip custom domain configuration.')
param customDomain string = ''

var resourceNamePrefix = '${environment}-codeflow-${regionAbbr}'
var containerAppName = '${resourceNamePrefix}-app'
var containerAppEnvName = '${resourceNamePrefix}-env'
var postgresServerName = '${resourceNamePrefix}-postgres-${uniqueString(resourceGroup().id, postgresLocation)}'
var redisCacheName = '${resourceNamePrefix}-redis'
var logAnalyticsWorkspaceName = '${resourceNamePrefix}-logs'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-10-02-preview' = {
  name: containerAppEnvName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = {
  name: postgresServerName
  location: postgresLocation
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: postgresLogin
    administratorLoginPassword: postgresPassword
    version: '15'
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
  }
}

resource postgresDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-06-01-preview' = {
  parent: postgresServer
  name: 'autopr'
}

resource postgresFirewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-06-01-preview' = {
  parent: postgresServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource redisCache 'Microsoft.Cache/redis@2023-08-01' = {
  name: redisCacheName
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

resource containerApp 'Microsoft.App/containerApps@2024-10-02-preview' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        allowInsecure: false
        transport: 'auto'
        customDomains: !empty(customDomain) ? [
          {
            name: customDomain
            bindingType: 'Auto'
          }
        ] : []
      }
      secrets: [
        {
          name: 'postgres-password'
          value: postgresPassword
        }
        {
          name: 'redis-password'
          value: redisPassword
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'codeflow-engine'
          image: containerImage
          env: [
            {
              name: 'AUTOPR_ENV'
              value: environment
            }
            {
              name: 'HOST'
              value: '0.0.0.0'
            }
            {
              name: 'PORT'
              value: '8080'
            }
            {
              name: 'POSTGRES_HOST'
              value: postgresServer.properties.fullyQualifiedDomainName
            }
            {
              name: 'POSTGRES_PORT'
              value: '5432'
            }
            {
              name: 'POSTGRES_DB'
              value: 'codeflow'
            }
            {
              name: 'POSTGRES_USER'
              value: postgresLogin
            }
            {
              name: 'POSTGRES_PASSWORD'
              secretRef: 'postgres-password'
            }
            {
              name: 'POSTGRES_SSLMODE'
              value: 'require'
            }
            {
              name: 'REDIS_HOST'
              value: redisCache.properties.hostName
            }
            {
              name: 'REDIS_PORT'
              value: '6380'
            }
            {
              name: 'REDIS_PASSWORD'
              secretRef: 'redis-password'
            }
            {
              name: 'REDIS_SSL'
              value: 'true'
            }
          ]
          resources: {
            cpu: json('1.0')
            memory: '2Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
        rules: [
          {
            name: 'http-rule'
            http: {
              metadata: {
                concurrentRequests: '100'
              }
            }
          }
        ]
      }
    }
  }
}

// Managed certificate must be created AFTER the container app
// because Azure requires the custom hostname to be added to a container app
// before a managed certificate can be created for it
resource managedCertificate 'Microsoft.App/managedEnvironments/managedCertificates@2024-10-02-preview' = {
  parent: containerAppEnv
  name: 'cert-${replace(customDomain, '.', '-')}'
  location: location
  properties: {
    subjectName: customDomain
    domainControlValidation: 'CNAME'
  }
  dependsOn: [
    containerApp
  ]
}

output containerAppName string = containerApp.name
output containerAppUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output customDomain string = customDomain
output postgresServerName string = postgresServer.name
output postgresFqdn string = postgresServer.properties.fullyQualifiedDomainName
output redisCacheName string = redisCache.name
output redisHostName string = redisCache.properties.hostName
