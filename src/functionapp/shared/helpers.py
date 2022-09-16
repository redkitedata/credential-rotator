import os
from datetime import timedelta, date, datetime, timezone
import importlib
from msgraph.core import GraphClient
from azure.data.tables import TableServiceClient

from azure.keyvault.secrets import SecretClient


def get_metastore_client(credential):
    """
    Returns a TableClient to interact with the Credential Rotator metastore.
    """
    table_service_client = TableServiceClient(
        endpoint=os.environ["AZURE_TABLE_STORAGE_ENDPOINT"], credential=credential
    )

    metastore_client = table_service_client.get_table_client(
        os.environ["CREDENTIAL_ROTATOR_METASTORE_TABLE_NAME"]
    )

    return metastore_client


def get_graph_client(credential):
    """
    Returns a GraphClient to interact with Microsoft Graph.
    """
    client = GraphClient(credential=credential)

    return client


def get_secret_client(credential, key_vault_uri):
    """
    Returns a SecretClient
    """
    client = SecretClient(vault_url=key_vault_uri, credential=credential)

    return client


def map_credential_type_to_class(credential_type):
    """
    Takes a string representation of a class name and returns a new/empty class of that type.
    """
    credential_type_mapper = {
        "ServicePrincipalCredential": getattr(
            importlib.import_module("shared.Credential.service_principal"),
            "ServicePrincipalCredential",
        )
    }

    credential_type = credential_type_mapper.get(credential_type)
    if credential_type is None:
        raise ValueError(
            f"Credential Class ({credential_type}) unknown. We do not know how to rotate it."
        )

    return credential_type


def create_meta_datetime_from_days_int(days: int):
    """
    Generates a datetime from an integer of days added to the current time.
    """
    dt = datetime.combine(
        date.today() + timedelta(days=days),
        datetime.min.time(),
    ).replace(tzinfo=timezone.utc)

    return dt
