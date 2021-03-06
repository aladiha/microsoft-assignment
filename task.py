import os 
import yaml
from azure.storage.blob import ContainerClient
from azure.cli.core import get_default_cli


# load config object
def load_config():
    dir_root = os.path.dirname(os.path.abspath(__file__))
    with open(dir_root + "/config.yaml", "r") as yamlfile:
        return yaml.load(yamlfile, Loader=yaml.FullLoader)

#create files in local storage
def create_files(dir, numberOfFiles):
    for i in range(1, numberOfFiles+1):
        with open(f'{dir}/{i}.txt', "w") as file:
            file.write(f'file number {i}') 

    print(f'created {numberOfFiles} files.')

# get files from local storage
def get_files(dir):
    with os.scandir(dir) as entries:
        for entry in entries:
            if entry.is_file() and not entry.name.startswith('.'):
                yield entry

# upload files to azure storage
def upload(files, connection_string, container_name):
    container_client = ContainerClient.from_connection_string(connection_string, container_name)
    print("uploading files to blob storage...")

    for file in files:
        blob_client = container_client.get_blob_client(file.name)
        with open(file.path, "rb") as data:
            blob_client.upload_blob(data)
            print(f'{file.name} uploaded to blob storage.')

#copy files from a storage account container to another
def copy_files(destinatinAccountKey, destinationAccountname, destinationContainer, sourceAccountKey, sourceAccountname, sourceContainer):
    print('copying blobs...')
    response = az_cli(f"storage blob copy start-batch \
    --account-key {destinatinAccountKey} \
    --account-name {destinationAccountname} \
    --destination-container {destinationContainer} \
    --source-account-key {sourceAccountKey} \
    --source-account-name {sourceAccountname} \
    --source-container {sourceContainer}")
    print("done copying.")
    return response

# invoke az CLI 
def az_cli (args_str):
    args = args_str.split()
    cli = get_default_cli()
    cli.invoke(args)
    if cli.result.result:
        return cli.result.result
    elif cli.result.error:
        raise cli.result.error
    return True


config = load_config()
create_files(config["source_folder"], 100)
files = get_files(config["source_folder2"])
upload(files, config["constring"], config["container"])
copy_files(config['storage2_account_key'], config['azure_storage2_name'], config['storage2_container_name'], config['storage1_account_key'], config['azure_storage1_name'], config['storage1_container_name'])



