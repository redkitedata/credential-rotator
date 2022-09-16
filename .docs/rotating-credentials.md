# Rotating Credentials

## Overview

Once a credential is registered in the Metastore it can be tracked for rotation. The `RotateCredential` function runs daily on a timer trigger, validating whether any credentials in the metastore are due for rotation. If any credentials are identified as in need of rotation, this is automatically handled by the function app.

All credential rotations follow a similar pattern:

- The credential is rotated in accordance with the logic defined in the `rotate_credential` function within its class.
- The value of the credential is then stored in the associated Key Vault.
- The credential is updated in the metastore to reflect its new expiration date along with any other details to guide future rotation behaviour.
