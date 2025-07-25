# Stage 1: Base image with common dependencies
FROM nvidia/cuda:12.6.3-cudnn-runtime-ubuntu24.04 AS base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1
# Speed up some cmake builds
ENV CMAKE_BUILD_PARALLEL_LEVEL=8

RUN apt update && apt install -y build-essential
# Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.12 \
    python3.12-venv \
    git \
    wget \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    ffmpeg \
    unzip\
    && ln -sf /usr/bin/python3.12 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install uv (latest) using official installer and create isolated venv
RUN wget -qO- https://astral.sh/uv/install.sh | sh \
    && ln -s /root/.local/bin/uv /usr/local/bin/uv \
    && ln -s /root/.local/bin/uvx /usr/local/bin/uvx \
    && uv venv /opt/venv

# Use the virtual environment for all subsequent commands
ENV PATH="/opt/venv/bin:${PATH}"

# Install comfy-cli + dependencies needed by it to install ComfyUI
RUN uv pip install comfy-cli pip setuptools wheel opencv-python

# Install ComfyUI
RUN /usr/bin/yes | comfy --workspace /comfyui install --version 0.3.30 --cuda-version 12.6 --nvidia

# Change working directory to ComfyUI
WORKDIR /comfyui

# Support for the network volume
ADD src/extra_model_paths.yaml ./



# Go back to the root
WORKDIR /

# Add application code and scripts
ADD src/start.sh test_input.json ./
RUN chmod +x /start.sh

RUN wget https://huggingface.co/AlienMachineAI/insightface-0.7.3-cp312-cp312-linux_x86_64.whl/resolve/main/insightface-0.7.3-cp312-cp312-linux_x86_64.whl
RUN pip uninstall insightface
RUN pip install insightface-0.7.3-cp312-cp312-linux_x86_64.whl
# Install Python runtime dependencies for the handler
RUN uv pip install runpod requests websocket-client firebase-admin

RUN pip install onnxruntime hydra-core>=1.3.2 numba addict timm yapf tqdm pillow>=9.4.0 piexif segment_anything
# Add script to install custom nodes
COPY scripts/comfy-node-install.sh /usr/local/bin/comfy-node-install
RUN chmod +x /usr/local/bin/comfy-node-install

# Prevent pip from asking for confirmation during uninstall steps in custom nodes
ENV PIP_NO_INPUT=1


# Copy helper script to switch Manager network mode at container start
COPY scripts/comfy-manager-set-mode.sh /usr/local/bin/comfy-manager-set-mode
RUN chmod +x /usr/local/bin/comfy-manager-set-mode

# Set the default command to run when starting the containe

ARG HUGGINGFACE_ACCESS_TOKEN

# Change working directory to ComfyUI
WORKDIR /comfyui

# Create necessary directories upfront
RUN mkdir -p models/checkpoints models/vae models/unet models/clip models/clip models/insightface models/insightface/models models/insightface/models/antelopev2 models/instantid models/instantid models/controlnet models/ipadapter custom_nodes

RUN git clone https://github.com/cubiq/ComfyUI_InstantID.git custom_nodes/ComfyUI_InstantID
RUN git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus.git custom_nodes/ComfyUI_IPAdapter_plus
RUN git clone https://github.com/Derfuu/Derfuu_ComfyUI_ModdedNodes.git custom_nodes/Derfuu_ComfyUI_ModdedNodes
RUN git clone https://github.com/cubiq/ComfyUI_essentials.git custom_nodes/ComfyUI_essentials
RUN git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git custom_nodes/comfyui_controlnet_aux
RUN git clone https://github.com/tsogzark/ComfyUI-load-image-from-url.git custom_nodes/ComfyUI-load-image-from-url
RUN git clone https://github.com/BadCafeCode/masquerade-nodes-comfyui.git custom_nodes/masquerade-nodes-comfyui
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack custom_nodes/ComfyUI-Impact-Pack
RUN git clone https://github.com/sipherxyz/comfyui-art-venture custom_nodes/comfyui-art-venture

WORKDIR /comfyui/models/insightface/models

RUN wget https://huggingface.co/MonsterMMORPG/tools/resolve/main/antelopev2.zip

RUN unzip antelopev2.zip

CMD ["/start.sh"]