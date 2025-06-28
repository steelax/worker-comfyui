#!/usr/bin/env bash

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po 'libtcmalloc.so.\d' | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# Ensure ComfyUI-Manager runs in offline network mode inside the container
comfy-manager-set-mode offline || echo "worker-comfyui: Could not set ComfyUI-Manager network_mode" >&2


echo "INITIALISATION worker-comfyui: Starting ComfyUI"
# Allow operators to tweak verbosity; default is DEBUG.
: "${COMFY_LOG_LEVEL:=DEBUG}"

if [ "$SERVE_API_LOCALLY" == "true" ]; then
  python -u /comfyui/main.py --disable-auto-launch --disable-metadata --listen --verbose "${COMFY_LOG_LEVEL}" --log-stdout &
  echo "worker-comfyui: Starting RunPod Handler"
  python -u /handler.py --rp_serve_api --rp_api_host=0.0.0.0
else

  echo "INITIALISATION worker-comfyui: Getting Latest Scripts from Network Store"
  wget -O /cert.json https://raw.githubusercontent.com/steelax/worker-comfyui/firebase/cert.json
  cp /cert.json /runpod_volume/sd/scripts/cert.json
  echo "INITIALISATION worker-comfyui: handler.py updated"

  wget -O /rp_firebase_upload.py https://raw.githubusercontent.com/steelax/worker-comfyui/firebase/rp_firebase_upload.py
  cp /rp_firebase_upload.py /runpod_volume/sd/scripts/rp_firebase_upload.py
  echo "INITIALISATION -comfyui: rp_firebase_upload.py updated"

  echo "Getting Dirs"
  ls /runpod-volume/sd
  echo "Getting Dirs 2"
  ls /runpod-volume/sd/custom_nodes
  echo "Getting Dirs 3"
  ls /comfyui/

  wget -O /handler.py https://raw.githubusercontent.com/steelax/worker-comfyui/firebase/handler.py
  cp /handler.py /runpod_volume/sd/scripts/handler.py
  echo "INITIALISATION worker-comfyui: handler.py updated"
  echo "INITIALISATION worker-comfyui: COMPLETE: Getting Latest Scripts from Network Store"

  echo "INITIALISATION worker-comfyui: Copying Custom Nodes from Network Store"
  cp /runpod_volume/sd/custom_nodes/ / -r
  echo "INITIALISATION worker-comfyui: COMPLETE: Copying Custom Nodes from Network Store"

  echo "INITIALISATION worker-comfyui: Getting Latest Scripts from git"
  wget -O /launch_comfy.sh https://raw.githubusercontent.com/steelax/worker-comfyui/firebase/src/launch_comfy.sh

  cp /runpod_volume/sd/custom_nodes/ /comfyui/ -r ;

  echo "INITIALISATION worker-comfyui: COMPLETE: Copying Custom Nodes from Network Store";

  /launch_comfy.sh;

fi