#!/usr/bin/env bash

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po 'libtcmalloc.so.\d' | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# Ensure ComfyUI-Manager runs in offline network mode inside the container
comfy-manager-set-mode offline || echo "worker-comfyui: Could not set ComfyUI-Manager network_mode" >&2

echo "worker-comfyui: Getting Latest Scripts from Network Store"
wget -O /handler.py https://raw.githubusercontent.com/steelax/worker-comfyui/firebase/handler.py
cp /handler.py /runpod_volume/sd/handler.py
echo "worker-comfyui: handler.py updated"

wget -O /rp_firebase_upload.py https://raw.githubusercontent.com/steelax/worker-comfyui/firebase/rp_firebase_upload.py
cp /rp_firebase_upload.py /runpod_volume/sd/rp_firebase_upload.py
echo "worker-comfyui: rp_firebase_upload.py updated"

echo "worker-comfyui: Starting ComfyUI"
# Allow operators to tweak verbosity; default is DEBUG.
: "${COMFY_LOG_LEVEL:=DEBUG}"

if [ "$SERVE_API_LOCALLY" == "true" ]; then
  python -u /comfyui/main.py --disable-auto-launch --disable-metadata --listen --verbose "${COMFY_LOG_LEVEL}" --log-stdout &
  echo "worker-comfyui: Starting RunPod Handler"
  python -u /handler.py --rp_serve_api --rp_api_host=0.0.0.0
else
  python -u /comfyui/main.py --disable-auto-launch --disable-metadata --verbose "${COMFY_LOG_LEVEL}" --log-stdout &
  echo "worker-comfyui: Starting RunPod Handler"
  python -u /handler.py
fi