param resourceToken string
param location string
param skuName string = 'Standard'
param topicName string = 'orders'

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: 'sb-${resourceToken}'
  location: location
  sku: {
    name: skuName
    tier: skuName
  }

  resource topic 'topics@2022-01-01-preview' = {
    name: topicName
    properties: {
      supportOrdering: true
    }
  
    resource subscription 'subscriptions@2022-01-01-preview' = {
      name: topicName
      properties: {
        deadLetteringOnFilterEvaluationExceptions: true
        deadLetteringOnMessageExpiration: true
        maxDeliveryCount: 10
      }
    }
  }
}

output SERVICEBUS_ENDPOINT string = serviceBusNamespace.properties.serviceBusEndpoint
