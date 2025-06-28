

import firebase_admin
from firebase_admin import credentials
from firebase_admin import storage



def upload_to_firebase(bucket, source_file_path, destination_blob_name):
    """Uploads a file to the bucket."""
    blob = bucket.blob(destination_blob_name)

    blob.upload_from_filename(source_file_path)
    blob.upload_from_string()

    print(f"File {source_file_path} uploaded to {destination_blob_name}.")

cred = credentials.Certificate(r'C:\Users\steph\PycharmProjects\worker-comfyui\cert.json')
firebase_admin.initialize_app(cred, {
    'storageBucket': 'podlax-serverless-image-oylm5z.firebasestorage.app'
})

bucket = storage.bucket()

upload_to_firebase(bucket,r'C:\Users\steph\PycharmProjects\worker-comfyui\ABC Logo.png','Inputs/test.jpg')
