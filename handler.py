import os
import base64
import tempfile
import traceback
from websocket import WebSocketApp, WebSocketConnectionClosedException, WebSocketTimeoutException

# Constants (adjust as needed)
WEBSOCKET_RECONNECT_ATTEMPTS = 3
WEBSOCKET_RECONNECT_DELAY_S = 5
COMFYUI_SERVER_URL = "http://localhost:8188"  # Update this to your ComfyUI server URL

def upload_to_firebase(bucket_name, image_data, file_path, cert):
    """Upload an image to Firebase Storage."""
    from firebase_admin import credentials, initialize_app, storage
    initialize_app(credentials.Certificate(cert))
    bucket = storage.bucket(bucket_name)
    blob = bucket.blob(file_path)
    blob.upload_from_string(image_data, content_type='image/png')
    print(f'Successfully uploaded {file_path} to Firebase.')

def get_image_data(filename, subfolder, img_type):
    """Fetch image data from ComfyUI server."""
    import requests
    url = f"{COMFYUI_SERVER_URL}/view?filename={filename}&subfolder={subfolder}&type={img_type}"
    response = requests.get(url)
    return response.content if response.status_code == 200 else None

def get_history(prompt_id):
    """Fetch execution history from ComfyUI server."""
    import requests
    url = f"{COMFYUI_SERVER_URL}/history/{prompt_id}"
    response = requests.get(url)
    return response.json() if response.status_code == 200 else {}

def _attempt_websocket_reconnect(ws_url, max_attempts, delay_s, closed_err):
    """Attempt to reconnect WebSocket."""
    import time
    for attempt in range(max_attempts):
        print(f"Attempting to reconnect ({attempt+1}/{max_attempts})...")
        try:
            ws = WebSocketApp(ws_url)
            return ws  # Successfully reconnected
        except Exception as e:
            if attempt < max_attempts - 1:
                time.sleep(delay_s)  # Wait before next attempt

    raise closed_err  # Reconnection failed after maximum attempts

def handler(event):
    """Main handler function for processing jobs."""
    import json
    job = event.get("job")
    job_id = job.get("id")

    try:
        # Initialize WebSocket connection
        ws_url = f"{COMFYUI_SERVER_URL}/ws"
        ws = WebSocketApp(ws_url)

        # Submit the job and wait for completion
        execution_done, errors = False, []
        while not execution_done and not errors:
            message = ws.recv()
            if not message:
                continue

            data = json.loads(message)
            if data.get("type") == "executing":
                prompt_id = data.get("data", {}).get("prompt_id")
                if prompt_id == job_id:
                    execution_done = True
                    break
            elif data.get("type") == "execution_error":
                error_details = data.get("data", {})
                errors.append(f"Execution error: {error_details}")

        # Fetch history and process outputs
        history = get_history(job_id)
        if not history:
            raise ValueError(f"No history found for job ID: {job_id}")

        prompt_history = history.get(job_id, {})
        outputs = prompt_history.get("outputs", {})

        output_data = []
        for node_id, node_output in outputs.items():
            # Handle image outputs
            if "images" in node_output:
                for image_info in node_output["images"]:
                    filename = image_info.get("filename")
                    subfolder = image_info.get("subfolder", "")
                    img_type = image_info.get("type")

                    if not filename or img_type == "temp":
                        continue

                    # Fetch and process image data
                    image_bytes = get_image_data(filename, subfolder, img_type)
                    if not image_bytes:
                        errors.append(f"Failed to fetch {filename} from ComfyUI.")
                        continue

                    # Upload the image (to Firebase or S3 as configured)
                    upload_to_firebase(
                        os.environ.get("FIREBASE_BUCKET_ENDPOINT_URL"),
                        base64.b64encode(image_bytes).decode('utf-8'),
                        f'users/{job_id}/outputs/{filename}.png',
                        json.loads(os.environ.get("FIREBASE_CERT"))
                    )

                    # Append image info to output data
                    output_data.append({
                        "filename": filename,
                        "type": "firebase_url",
                        "data": f"gs://{os.environ.get('FIREBASE_BUCKET_ENDPOINT_URL')}/users/{job_id}/outputs/{filename}.png"
                    })

        # Return results
        result = {"images": output_data, "errors": errors} if output_data else {"error": "No images found", "details": errors}
    except Exception as e:
        print(f"Handler error: {e}")
        traceback.print_exc()
        return {"error": str(e)}

    finally:
        if ws.connected:
            ws.close()

    return result

if __name__ == "__main__":
    import runpod
    print("Starting RunPod handler...")
    runpod.serverless.start({"handler": handler})