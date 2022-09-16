# Adding a New Credential Type

This function app is designed in an extensible way so that we can continuously define new credential types for rotation.

To create a new credential, you must first create a new file under `shared\Credential`. The `base.py` file represents the base credential class that all new classes must inherit from. This class is implemented as an abstract class - it can not be instantiated directly, but child classes that inherit from it can use any methods which have been defined inside it through the use of `super()`. You will notice in existing classes such as `ServicePrincipalCredential` that `super()` is frequently used to defer common functionality of all classes back to the base class to avoid unnecessary code repetition.

Once you have created a new file, the following code block provides a starting point for implementing your own credentials for rotation.

Step through the numbered comments in the code and update as required.

``` py
from dataclasses import dataclass
from datetime import datetime
from azure.keyvault.secrets import SecretClient
from azure.data.tables import TableClient
from msgraph.core import GraphClient
from shared.Credential.base import Credential


# 1. Name your new class! I'm going with "ShinyNewCredential". 
#    It should inherit from the Credential base class as well.
@dataclass
class ShinyNewCredential(Credential):

    # 2. Time to define the properties that are unique to this credential!
    #    What do we need from the user to successfully rotate this credential?
    SomeImportantProperty: str = None
    AnotherImportantProperty: str = None

    # 3. Leave the following functions to inherit from the base class.
    def __post_init__(self):
        super().__post_init__()

    def upsert_key_vault_record(self, client: SecretClient):
        super().upsert_key_vault_record(client)

    def upsert_metastore_record(self, client: TableClient, properties):
        super().upsert_metastore_record(client, properties)

    # 4. How do we go about rotating your credential? You need to define the process here.
    #
    #   Make sure you set the classes "_SecretValue" property with the new credential 
    #   so we can write it back to Key Vault!
    def rotate_credential(self, credential):
        # Your custom rotation code goes here!
        # ...

        self._SecretValue = {{ YOUR SECRET HERE }}

    # 5. We need to express the properties of this class as a dictionary to 
    #    write back to the Credential Metastore.
    #
    #    You only need to create a property dictionary for the properties 
    #    you defined at the top of the class - we'll accesss the other base 
    #    properties from the base class!
    def generate_metastore_dict(self):
        # Change this based on your classes custom properties.
        this_dict = {
            "SomeImportantProperty": self.SomeImportantProperty,
            "AnotherImportantProperty": self.AnotherImportantProperty,
        }

        # Leave this code so we can merge the properties into a single dictionary!
        base_dict = super().generate_metastore_dict()
        merged_dict = {**base_dict, **this_dict}

        return merged_dict
```
