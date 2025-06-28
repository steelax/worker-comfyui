#!/usr/bin/env bash

python -u /comfyui/main.py --disable-auto-launch --disable-metadata --verbose "${COMFY_LOG_LEVEL}" --log-stdout &
echo "LAUNCHER worker-comfyui: Starting RunPod Handler"
python -u /handler.py