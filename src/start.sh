#!/usr/bin/env bash

echo "worker-comfyui: getting latest shell script"
wget -O /main_run.sh https://raw.githubusercontent.com/steelax/worker-comfyui/firebase/src/main_run.sh
chmod +x /main_run.sh  # Ensure the downloaded script is executable
echo "worker-comfyui: running latest shell script"
/main_run.sh