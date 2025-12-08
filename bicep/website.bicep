@description('Environment name (prod, dev, staging)')
param environment string = 'prod'

@description('Azure region abbreviation (e.g., san for South Africa North, eus for East US)')
param regionAbbr string = 'san'

@description('Azure region full name')
param location string = 'eastus2'

@description('Custom domain name')
param customDomain string = 'autopr.io'

var resourceNamePrefix = '${environment}-stapp-${regionAbbr}-autopr'
var staticWebAppName = resourceNamePrefix

resource staticWebApp 'Microsoft.Web/staticSites@2022-03-01' = {
  name: staticWebAppName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    repositoryUrl: 'https://github.com/JustAGhosT/autopr-engine'
    branch: 'main'
    buildProperties: {
      appLocation: 'website'
      apiLocation: ''
      appArtifactLocation: 'out'
      outputLocation: 'out'
    }
  }
}

// Custom domain binding - automatically configures the domain
resource customDomainBinding 'Microsoft.Web/staticSites/customDomains@2022-03-01' = {
  parent: staticWebApp
  name: customDomain
  properties: {}
}

output staticWebAppName string = staticWebApp.name
output staticWebAppUrl string = staticWebApp.properties.defaultHostname
output resourceGroupName string = resourceGroup().name
output customDomain string = customDomain
output customDomainValidationToken string = staticWebApp.id
