# Function App

## Introduction

Function App for managing the rotation of credentials across an Azure Platform.

## Components

The Credential Rotator is provided as an Azure Function application, which exposes the functions `RegisterCredential` and `RotateCredential`.

Documentation for how the functions operate can be found here:

- [RegisterCredential](.docs/registering-credentials.md)
- [RotateCredential](.docs/rotating-credentials.md)

## Requirements

This function app requires certain permissions to work. Depending on the credentials you need rotated, you may only need a subset of permissions.

### Base Permissions (Must Have!)

- The Function App uses a Service Principal to manage Credential Rotation. The Function App assumes the Service Principal by virtue of the details being defined in the Function Apps environmental settings. These are configured as part of the Bicep included with this project, but if you are developing locally you will need to define these in your `local.settings.json` file - see [Developer Reference](#developer-reference) section below.

- The Service Principal requires the `Storage Table Data Contributor` role on the Azure Function storage account in order to store Credential metadata. This is handled for you as part of the Bicep deployment.
- Needs to have an access policy on any Key Vaults it updates. This is also handled for you with the Bicep deployment.

### Service Principal Rotation Permissions

- The Service Principal the function app uses to manage other Service Principals needs the `Directory.Read.All` + `Application.ReadWrite.OwnedBy` AD Roles to scan for applications and manage the ones it owns. Here's an example of how this should look from within Azure AD:

![AD Roles](.media/ADRole.png)

- The Service Principal needs to be an owner of the Service Principal it wants to manage. [I've created a useful script for doing that here](.docs/scripts/configure-sp-ownership/README.md) as its not actually possible to assign this via the Portal!
