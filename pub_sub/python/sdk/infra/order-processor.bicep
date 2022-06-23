@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unqiue hash used in all resources.')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string

param imageName string

var resourceToken = toLower(uniqueString(subscription().id, name, location))
var tags = {
  'azd-env-name': name
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: 'cae-${resourceToken}'
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' existing = {
  name: 'contreg${resourceToken}'
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: 'appi-${resourceToken}'
}

resource api 'Microsoft.App/containerApps@2022-01-01-preview' existing = {
  name: 'ca-api-${resourceToken}'
}

resource web 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'ca-web-${resourceToken}'
  location: location
  tags: union(tags, {
      'azd-service-name': 'web'
    })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: true
        targetPort: 80
        transport: 'auto'
      }
      secrets: [
        {
          name: 'registry-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
      ]
      registries: [
        {
          server: '${containerRegistry.name}.azurecr.io'
          username: containerRegistry.name
          passwordSecretRef: 'registry-password'
        }
      ]
    }
    template: {
      containers: [
        {
          image: imageName
          name: 'main'
          env: [
            {
              name: 'REACT_APP_APPINSIGHTS_INSTRUMENTATIONKEY'
              value: appInsights.properties.InstrumentationKey
            }
            {
              name: 'REACT_APP_API_BASE_URL'
              value: 'https://${api.properties.configuration.ingress.fqdn}'
            }
          ]
        }
      ]
    }
  }
}

output WEB_URI string = 'https://${web.properties.configuration.ingress.fqdn}'
