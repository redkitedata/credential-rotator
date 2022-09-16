import logging
from datetime import datetime, timezone
from dataclasses import fields
from azure.identity import EnvironmentCredential
import azure.functions as func
from shared.helpers import (
    get_metastore_client,
    map_credential_type_to_class,
    get_secret_client,
)


def main(mytimer: func.TimerRequest) -> None:
    """
    Registers the provided credential in the metastore based on a JSON body sent with the request.
    """
    logging.info("Python HTTP trigger function processed a request.")

    # Gets the signed in identities credential.
    azure_credential = EnvironmentCredential()

    # Returns a TableClient to interact with Azure Table metastore.
    metastore_client = get_metastore_client(azure_credential)

    # Generates a date filter to pass into our query when returning objects from Azure Table Storage.
    date_filter = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%MZ")

    # Execute the query against Azure Table Storage, returning entities that are ready for rotation.
    queried_entities = metastore_client.query_entities(
        f"NextRotationDate lt datetime'{date_filter}'"
    )

    for entity in queried_entities:
        # Takes the "CredentialType" defined in the request body to return the underlying class (uninstantiated).
        credential_class = map_credential_type_to_class(entity["CredentialType"])

        # Determine the list of field names expected to be initialised by the Credential Class.
        props_to_init = list(f for f in fields(credential_class) if f.init is True)

        # Apply the filtered field names to the entity we are iterating over.
        filtered_entity = {f.name: entity[f.name] for f in props_to_init}

        # Instantiate the credential class using properties from TableEntity, filtered to only relevant fields.
        credential_instance = credential_class(**filtered_entity)

        # Instantiate the credential class by passing in the req_body as keyword arguments (kwargs).
        credential_instance.rotate_credential(azure_credential)

        # Returns a SecretClient to interact with Azure Key Vault. This is done per entity as values may exist across different KVs.
        secret_client = get_secret_client(
            azure_credential,
            f"https://{credential_instance.PartitionKey}.vault.azure.net",
        )

        # Upsert the new secret value into Azure Key Vault.
        credential_instance.upsert_key_vault_record(secret_client)

        # Returns a dictionary object for the credential that contains all the required metadata for the metastore.
        entity_properties = credential_instance.generate_metastore_dict()

        # Upserts the dicitonary into the metastore.
        credential_instance.upsert_metastore_record(metastore_client, entity_properties)
