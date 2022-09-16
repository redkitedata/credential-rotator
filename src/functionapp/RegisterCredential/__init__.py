import logging
from azure.data.tables import UpdateMode
from azure.identity import EnvironmentCredential
import azure.functions as func
from shared.helpers import (
    get_metastore_client,
    map_credential_type_to_class,
)


def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    Registers the provided credential in the metastore based on a JSON body sent with the request.
    """
    logging.info("Python HTTP trigger function processed a request.")

    try:
        req_body = req.get_json()
    except ValueError:
        pass

    azure_credential = EnvironmentCredential()

    # Returns a TableClient to interact with Azure Table metastore.
    metastore_client = get_metastore_client(azure_credential)

    # Takes the "CredentialType" defined in the request body to return the underlying class (uninstantiated).
    credential_class = map_credential_type_to_class(req_body["CredentialType"])

    # Instantiate the credential class by passing in the req_body as keyword arguments (kwargs).
    credential_instance = credential_class(**req_body)

    # Returns a dictionary object for the credential that contains all the required metadata for the metastore.
    entity_properties = credential_instance.generate_metastore_dict()

    # Upserts the dicitonary into the metastore.
    credential_instance.upsert_metastore_record(metastore_client, entity_properties)

    return func.HttpResponse("This HTTP triggered function executed successfully.")
