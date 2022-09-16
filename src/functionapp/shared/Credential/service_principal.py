from dataclasses import dataclass
import json
from datetime import datetime
from azure.keyvault.secrets import SecretClient
from azure.data.tables import TableClient
from msgraph.core import GraphClient
from shared.Credential.base import Credential


@dataclass
class ServicePrincipalCredential(Credential):
    """
    Credential for a Service Principal in Azure.
    Extends additional properties from Credential, including how to rotate the SP Credential.
    """

    # Properties unique to this class.
    AppRegName: str = None
    AppRegObjectId: str = None

    # Validate class properties in accordance with base class definition.
    def __post_init__(self):
        super().__post_init__()

    # Functionality can be deferred to base class.
    def upsert_key_vault_record(self, client: SecretClient):
        super().upsert_key_vault_record(client)

    # Functionality can be deferred to base class.
    def upsert_metastore_record(self, client: TableClient, properties):
        super().upsert_metastore_record(client, properties)

    # Every class that inherits from Credential must define its own rotation functionality.
    def rotate_credential(self, credential):
        client = GraphClient(credential=credential)
        application = self.get_application(client, self.AppRegObjectId)
        body = self.get_new_secret_post_req_body(
            f"Automatic Rotation - {datetime.today().strftime('%Y-%m-%d')}",
            self.NextExpirationDate.isoformat(),
        )
        res = self.post_new_secret(client, application, body)

        if res.status_code != 403:
            self._SecretValue = json.loads(res.content)["secretText"]
        else:
            raise Exception(res.text)

    # Generates a dictionary of properties to write back to the Credential Metastore.
    # Combines any attributes of this class with the base class.
    def generate_metastore_dict(self):
        # Base properties of all Credentials.
        base_dict = super().generate_metastore_dict()

        # Properties unique to this class.
        this_dict = {
            "AppRegObjectId": self.AppRegObjectId,
            "AppRegName": self.AppRegName,
        }

        # Merge the two dictionaries together.
        merged_dict = {**base_dict, **this_dict}

        return merged_dict

    # Following functions are unique to this class!

    def get_application(self, client: GraphClient, app_reg_object_id):
        """
        Returns a Service Principal (Application) based on an app reg object id.
        """
        application = client.get(f"/applications/{app_reg_object_id}")

        if application is None:
            raise Exception(
                "Application does not exist in AAD, or client has insufficient permissions to query AAD."
            )

        application = json.loads(application.content)

        return application

    def post_new_secret(self, client, application, new_cred_body):
        """
        Executes a POST request for creating a new Service Principal secret.
        """
        res = client.post(
            f'/applications/{application["id"]}/addPassword',
            headers={"Content-type": "application/json"},
            data=new_cred_body,
        )

        return res

    def get_new_secret_post_req_body(
        self, service_principal_name, expiration_iso_datetime
    ):
        """
        Generates a POST Request body that is used to rotate SP Secrets.
        """

        body = json.dumps(
            {
                "passwordCredential": {
                    "displayName": service_principal_name,
                    "endDateTime": expiration_iso_datetime,
                }
            }
        )

        return body
