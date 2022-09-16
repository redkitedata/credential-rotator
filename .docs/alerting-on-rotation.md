# Alerting On Rotation

While the Credential Rotator Application is designed to be extensible to support new Credential Types and updated logic, there are inevitably use cases where manual tasks need to be carried out on rotation (e.g. updating a Service Connection in DevOps that is dependant on a Service Principal's newly rotated secret). The Credential Rotator application alerts named users via SendGrid to deliver email notifications when a Credential has been rotated in Key Vault so that these manual actions can be performed where required.

The function is triggered by Event Grid whenever a new secret version is updated in Key Vault, provided that it is not named with the reserved `metacr` prefix.
