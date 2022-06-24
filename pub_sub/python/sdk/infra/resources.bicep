param name string
param location string
param principalId string = ''
param resourceToken string
param tags object
param apiImageName string = ''
param webImageName string = ''

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-01-01-preview' = {
  name: 'cae-${resourceToken}'
  location: location
  tags: tags
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

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' = {
  name: 'contreg${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
    anonymousPullEnabled: false
    dataEndpointEnabled: false
    encryption: {
      status: 'disabled'
    }
    networkRuleBypassOptions: 'AzureServices'
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: 'keyvault${resourceToken}'
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: []
  }

}

resource keyVaultAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2021-11-01-preview' = if (!empty(principalId)) {
  name: '${keyVault.name}/add'
  properties: {
    accessPolicies: [
      {
        objectId: principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}

module serviceBusResources './servicebus.bicep' = {
  name: 'servicebus-${resourceToken}'
  params: {
    location: location
  }
}

module appInsightsResources './appinsights.bicep' = {
  name: 'appinsights-${resourceToken}'
  params: {
    resourceToken: resourceToken
    location: location
    tags: tags
  }
}

module checkoutImageName './checkout.bicep' = {
  name: 'api-resources-${resourceToken}'
  params: {
    name: name
    location: location
    imageName: apiImageName != '' ? apiImageName : 'nginx:latest'
  }
  dependsOn: [
    containerAppsEnvironment
    containerRegistry
    appInsightsResources
    keyVault
  ]
}

module orderprocessorImageName './order-processor.bicep' = {
  name: 'web-resources-${resourceToken}'
  params: {
    name: name
    location: location
    imageName: webImageName != '' ? webImageName : 'nginx:latest'
  }
  dependsOn: [
    containerAppsEnvironment
    containerRegistry
    appInsightsResources
    keyVault
  ]
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: 'log-${resourceToken}'
  location: location
  tags: tags
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}


output AZURE_COSMOS_CONNECTION_STRING_KEY string = 'AZURE-COSMOS-CONNECTION-STRING'
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.properties.vaultUri
output SERVICEBUS_ENDPONT string = serviceBusResources.outputs.SERVICEBUS_ENDPOINT
output APPINSIGHTS_INSTRUMENTATIONKEY string = appInsightsResources.outputs.APPINSIGHTS_INSTRUMENTATIONKEY
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.properties.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.name
output CHECKOUT_APP_URI string = checkoutImageName.outputs.API_URI
output ORDER_API_URI string = orderprocessorImageName.outputs.WEB_URI
