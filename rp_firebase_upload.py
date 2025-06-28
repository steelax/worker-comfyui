import runpod
from runpod.serverless.utils import rp_upload
import json
import urllib.request
import urllib.parse
import time
import os
import requests
import base64
from io import BytesIO
import websocket
import uuid
import tempfile
import socket
import traceback

# Firebase-related code (assuming you have this part)
from firebase_admin import credentials, initialize_app, storage

def upload_to_firebase(bucket_name, source_file_path, destination_blob_name):
    """Uploads a file to the bucket."""
    bucket = storage.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)

    blob.upload_from_filename(source_file_path)

    print(f"File {source_file_path} uploaded to {destination_blob_name}.")

def download_from_firebase(bucket_name, source_blob_name, destination_file_path):
    """Downloads a file from the bucket."""
    bucket = storage.bucket(bucket_name)
    blob = bucket.blob(source_blob_name)

    blob.download_to_filename(destination_file_path)

    print(f"File {source_blob_name} downloaded to {destination_file_path}.")


from firebase_admin import firestore
