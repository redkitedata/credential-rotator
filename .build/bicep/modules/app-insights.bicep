@description('Required. The name of the Application Insights Resorce.')
param name string

@description('Required. The location of the Application Insights Resorce.')
param location string

@description('Optional. Any tags to apply to the resource.')
param tags object

resource appInsights 'microsoft.insights/components@2020-02-02' = {
  name: name
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: 90
    IngestionMode: 'ApplicationInsights'
  }
}

output instrumentationKey string = appInsights.properties.InstrumentationKey
