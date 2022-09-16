from dataclasses import dataclass, field
from datetime import datetime
from abc import ABCMeta, abstractmethod
from azure.keyvault.secrets import SecretClient
from azure.data.tables import UpdateMode, TableClient
from shared.helpers import create_meta_datetime_from_days_int


@dataclass
class Credential(metaclass=ABCMeta):
    """
    Defines a Credential for Rotation.
    This includes common properties, post init property validation, and functions for rotation.
    """

    PartitionKey: str
    RowKey: str
    CredentialType: str
    DaysUntilExpiration: int
    DaysUntilRotation: int

    NextExpirationDate: datetime = field(init=False)
    NextRotationDate: datetime = field(init=False)
    _SecretValue: str = field(init=False)

    @abstractmethod
    def __post_init__(self):
        if self.DaysUntilRotation <= 0:
            raise ValueError("DaysUntilRotation must be greater than zero")

        if self.DaysUntilExpiration <= 0:
            raise ValueError("DaysUntilExpiration must be greater than zero")

        if self.DaysUntilExpiration < self.DaysUntilRotation:
            raise ValueError(
                "DaysUntilRotation must be greater than or equal to DaysUntilExpiration to prevent secret expiration before rotation"
            )

        self.NextExpirationDate = create_meta_datetime_from_days_int(
            self.DaysUntilExpiration
        )

        self.NextRotationDate = create_meta_datetime_from_days_int(
            self.DaysUntilRotation
        )

        self._SecretValue = None

    @abstractmethod
    def rotate_credential(self, credential):
        """
        Rotates a credential (behaviour is implemented by child class).
        """
        return NotImplemented

    @abstractmethod
    def upsert_key_vault_record(self, client: SecretClient):
        """
        Sets the value of a Key Vault secret.
        """
        client.set_secret(
            self.RowKey, self._SecretValue, expires_on=self.NextExpirationDate
        )

    @abstractmethod
    def generate_metastore_dict(self):
        """
        Converts the Credential class into a dictionary that can be written to Azure Table Storage.
        """
        prop_dict = {
            "PartitionKey": self.PartitionKey,
            "RowKey": self.RowKey,
            "CredentialType": self.CredentialType,
            "DaysUntilExpiration": self.DaysUntilExpiration,
            "DaysUntilRotation": self.DaysUntilRotation,
            "NextExpirationDate": self.NextExpirationDate,
            "NextRotationDate": self.NextRotationDate,
        }

        return prop_dict

    @abstractmethod
    def upsert_metastore_record(self, client: TableClient, properties: dict):
        """
        Upserts data record into Azure Table metastore.
        """
        client.upsert_entity(properties, UpdateMode.REPLACE)
