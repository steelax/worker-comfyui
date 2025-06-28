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

RUN wget https://huggingface.co/AlienMachineAI/insightface-0.7.3-cp312-cp312-linux_x86_64.whl/resolve/main/insightface-0.7.3-cp312-cp312-linux_x86_64.whl
RUN pip uninstall insightface
RUN pip install insightface-0.7.3-cp312-cp312-linux_x86_64.whl
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

# Install Python runtime dependencies for the handler
RUN uv pip install runpod requests websocket-client firebase-admin

RUN pip install onnxruntime
# Add script to install custom nodes
COPY scripts/comfy-node-install.sh /usr/local/bin/comfy-node-install
RUN chmod +x /usr/local/bin/comfy-node-install

# Prevent pip from asking for confirmation during uninstall steps in custom nodes
ENV PIP_NO_INPUT=1


# Copy helper script to switch Manager network mode at container start
COPY scripts/comfy-manager-set-mode.sh /usr/local/bin/comfy-manager-set-mode
RUN chmod +x /usr/local/bin/comfy-manager-set-mode

# Set the default command to run when starting the container
CMD ["/start.sh"]

# Stage 2: Download models
FROM base AS downloader

ARG HUGGINGFACE_ACCESS_TOKEN

# Change working directory to ComfyUI
WORKDIR /comfyui

# Create necessary directories upfront
RUN mkdir -p models/checkpoints models/vae models/unet models/clip models/clip models/insightface models/insightface/models models/insightface/models/antelopev2 models/instantid models/instantid models/controlnet models/ipadapter custom_nodes

RUN cp /runpod_volume/sd/custom_nodes/ / -r

WORKDIR /comfyui/models/insightface/models
RUN wget https://huggingface.co/MonsterMMORPG/tools/resolve/main/antelopev2.zip
RUN unzip antelopev2.zip
#COPY /runpod-volume/sd/extra_model_paths.yaml /comfyui/extra_model_paths.yaml


# Stage 3: Final image
FROM base AS final
# Copy models from stage 2 to the final image
COPY --from=downloader /comfyui/models /comfyui/models

COPY --from=downloader /comfyui/custom_nodes /comfyui/custom_nodes

RUN export BUCKET_ENDPOINT_URL=https://podlax.s3.eu-west-2.amazonaws.com/
