import zipfile
import os
from google.cloud import storage

storage_client = storage.Client()


def download_blob(bucket_name, source_blob_name, destination_file_name):
    """Downloads a blob from the bucket."""
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(bucket_name)
    blob = bucket.blob(source_blob_name)

    blob.download_to_filename(destination_file_name)

    print('Blob {} downloaded to {}.'.format(
        source_blob_name,
        destination_file_name))

def unzip(source, destination):
    with zipfile.ZipFile(source,"r") as zip_ref:
        zip_ref.extractall(destination)

def upload_blob(bucket_name, source_file_name, destination_blob_name):
    """Uploads a file to the bucket."""
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)

    blob.upload_from_filename(source_file_name)

    print('File {} uploaded to {}.'.format(
        source_file_name,
        destination_blob_name))

def hello_gcs(event, context):
    file = event
    zipped = False
    
    source_file_name = file['name']
    if source_file_name.endswith('zip'):
        zipped = True
    source_bucket_name = os.environ.get('sourcebucket')

    destination_bucket_name =  os.environ.get('destinationbucket')
    destination_file_name = source_file_name.replace('.zip','')
    destination_file_zip = "/tmp/{0}".format(source_file_name)
    destination = '/tmp/'
    destination_file_unzipped = "/tmp/{0}".format(destination_file_name)
    download_blob(source_bucket_name, source_file_name, destination_file_zip)
    
    if zipped:
        destination = '/tmp/unzipped/'
        destination_file_unzipped = "/tmp/unzipped/{0}".format(destination_file_name)
        unzip(destination_file_zip, destination)
        
    upload_blob(destination_bucket_name, destination_file_unzipped, destination_file_name)
    print(f"Processing file: {file['name']}.")