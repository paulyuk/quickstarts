param name string
param location string
param principalId string = ''
param resourceToken string
param tags object
param ordersImageName string = ''
param checkoutImageName string = ''

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-01-01-preview' = {
  name: 'cae-${resourceToken}'
  location: location
  dependsOn: [
    serviceBusResources
  ]
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }

  resource daprComponent 'daprComponents@2022-03-01' = {
    name: 'orderpubsub'
    properties: {
      componentType: 'pubsub.azure.servicebus'
      version: 'v1'
      secrets: [
        {
          name: 'sb-root-connectionstring'
          value: '${listKeys('${sb.id}/AuthorizationRules/RootManageSharedAccessKey', sb.apiVersion).primaryConnectionString};EntityPath=orders'
        }
      ]
      metadata: [
        {
          name: 'connectionString'
          secretRef: 'sb-root-connectionstring'
        }
        {
          name: 'consumerID'
          value: 'orders'
        }
      ]
      scopes: []
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

resource sb 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' existing = {
  name: serviceBusResources.name
}

module serviceBusResources './servicebus.bicep' = {
  name: 'sb-${resourceToken}'
  params: {
    resourceToken: resourceToken
    location: location
    skuName: 'Standard'
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

module checkout './checkout.bicep' = {
  name: 'api-resources-${resourceToken}'
  params: {
    name: name
    location: location
    imageName: checkoutImageName != '' ? checkoutImageName : 'nginx:latest'
  }
  dependsOn: [
    containerAppsEnvironment
    containerRegistry
    appInsightsResources
    keyVault
    keyVaultAccessPolicies
    serviceBusResources
  ]
}

module orders './orders.bicep' = {
  name: 'web-resources-${resourceToken}'
  params: {
    name: name
    location: location
    imageName: ordersImageName != '' ? ordersImageName : 'nginx:latest'
  }
  dependsOn: [
    containerAppsEnvironment
    containerRegistry
    appInsightsResources
    keyVault
    keyVaultAccessPolicies
    serviceBusResources
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
output CHECKOUT_APP_URI string = checkout.outputs.CHECKOUT_URI
output ORDERS_APP_URI string = orders.outputs.ORDERS_URI
