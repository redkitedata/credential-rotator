import os
import argparse
import requests
import pyjson5
from azure.identity import DefaultAzureCredential

# Parse in Enterprise Application Object ID from command line.
parser = argparse.ArgumentParser(description="Configure SP Ownership")
parser.add_argument(
    "-i", "--enterprise-app-object-id", dest="enterprise_app_object_id", required=True
)
parser.add_argument(
    "-f",
    "--applications-relative-filepath",
    nargs="?",
    const="managed-apps.json",
    default="managed-apps.json",
    dest="managed_apps_relative_path",
)
args = parser.parse_args()

# Don't update these unless you know what you are doing!
token = None
headers = None
graph_api_version = "beta"
uri = "https://graph.microsoft.com/{api_version}/{endpoint}"

# This script uses the logged in user to set Application Registration ownership.
# If you don't already own the target Applications or have a suitable permission, this won't do anything!
os.system("az login")


def authenticate():
    global token
    global headers

    scope = "https://graph.microsoft.com/.default"

    credential = DefaultAzureCredential(
        exclude_shared_token_cache_credential=True,
        exclude_visual_studio_code_credential=True,
        exclude_powershell_credential=True,
    )

    token = credential.get_token(scope)
    headers = {"Authorization": f"Bearer {token.token}"}


def http_get(api_version, endpoint):
    target_uri = uri.format(api_version=api_version, endpoint=endpoint)
    response = requests.get(target_uri, headers=headers).json()
    return response


def http_post(api_version, endpoint, data):
    target_uri = uri.format(api_version=api_version, endpoint=endpoint)
    additional_headers = {"Content-Type": "application/json"}
    response = requests.post(
        target_uri, headers={**headers, **additional_headers}, json=data
    )
    return response


def get_apps_to_manage():
    managed_apps_fqp = os.path.join(
        os.path.abspath(os.path.dirname(__file__)), args.managed_apps_relative_path
    )
    f = open(managed_apps_fqp, "rb")
    json = pyjson5.load(f)

    return json


print("Logging in via Azure CLI...")
authenticate()

print(
    f"Retrieving applications to manage from file {args.managed_apps_relative_path}..."
)
apps = get_apps_to_manage()

for app in apps:
    # The "Client Secret" belongs to the app registration, so this is the AD object we need to manage.
    # Let's check if we are in fact an owner of the application to begin with.
    owners = http_get(graph_api_version, f"/applications/{app['id']}/owners")

    # If the enterprise app this function app is using is not already an owner of the target application, add it.
    if not any([args.enterprise_app_object_id in x["id"] for x in owners["value"]]):
        print(
            f"Adding Enterprise Application {args.enterprise_app_object_id} as  to {app['id']}..."
        )
        data = {
            "@odata.id": f"https://graph.microsoft.com/beta/directoryObjects/{args.enterprise_app_object_id}"
        }

        result = http_post(
            graph_api_version,
            f"/applications/{app['id']}/owners/$ref",
            data,
        )
    else:
        print(
            f"Enterprise Application {args.enterprise_app_object_id} is already an owner of {app['id']}!"
        )

print("Application Ownership successfully updated.")
