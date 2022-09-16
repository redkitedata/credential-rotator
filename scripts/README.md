# Automating Service Principal AD Configuration

Ensure you have activated your Virtual Environment and installed the necessary requirements as mentioned in the [README](../README.md#virtual-environment-activation).

You can then update the [managed-apps.json](./managed-apps.json) file with the Application Registration Object IDs of the Service Principals you wish to manage as found in Azure Active Directory. You can define any additional metadata as required e.g. Service Principal Name, although this is not used by the scripts.

When executing the `configure.py` script, the **Enterprise App** Object ID of the Service Principal which represents the function app must be provided as a command line argument. Don't confuse this with the Application Registration Object ID used in the applications.json file - they are different!

``` sh
python -m venv .venv # Depending on how you've setup python you may need to use python3 instead.
.venv/Scripts/activate
pip install -r src/functionapp/requirements.txt
python scripts/configure.py --enterprise-app-object-id 8370e35f-10eb-4df0-ab36-5e14d20ba6cc # replace this ID with your own.
```

When running this script you will be prompted to login to Azure via the Azure CLI. You should login with an account that has permissions to assign the Credential Rotator's Service Principal ownership of the other Principals.
