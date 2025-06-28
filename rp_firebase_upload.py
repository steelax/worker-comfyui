import json

import firebase_admin
from firebase_admin import credentials
from firebase_admin import storage
import base64


def file_to_base64(file_path):
    """Converts the contents of a file to a Base64-encoded string."""
    with open(file_path, 'rb') as file:
        encoded_string = base64.b64encode(file.read()).decode('utf-8')
    return encoded_string

def upload_to_firebase(bucket_url, data, destination_blob_name, cert):
    base64_version = base64.b64encode(data)
    json_credentials = json.loads(cert)
    """Uploads a file to the bucket from Base64 string."""
    print(destination_blob_name)
    cred = credentials.Certificate(json_credentials)
    firebase_admin.initialize_app(cred, {
        'storageBucket': bucket_url
    })

    # Get the storage bucket
    bucket = storage.bucket()

    try:
        # Decode the Base64 string
        image_data = base64.b64decode(base64_version)

        # Create blob object
        blob = bucket.blob(destination_blob_name)

        # Upload binary data from string
        blob.upload_from_string(image_data, content_type='image/png')

        print(f"Base64 string uploaded to {destination_blob_name}.")
        return True

    except Exception as e:
        print(f"An error occurred: {e}")
        return False

