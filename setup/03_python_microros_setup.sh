#!/bin/bash
# =============================================================================
# ABU Robocon 2027 — Step 3: Python AI/Vision Stack
# OpenCV + Ultralytics YOLOv8 + PyTorch (for block & Mustika detection)
# micro-ROS Agent (for STM32 / Arduino ↔ ROS 2 bridge)
# =============================================================================
set -e

echo "=============================================="
echo "  Python Vision Stack & micro-ROS Agent"
echo "=============================================="

# --- 1. System Python deps ---
sudo apt install -y \
    python3-pip \
    python3-venv \
    python3-opencv \
    python3-numpy \
    python3-scipy \
    python3-matplotlib \
    libopencv-dev

# --- 2. Create a dedicated venv for Robocon AI work ---
VENV_DIR="$HOME/robocon_venv"
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR" --system-site-packages
    echo "✅ Created virtual environment at $VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

# --- 3. Install Python packages inside venv ---
pip install --upgrade pip wheel setuptools
pip install \
    ultralytics \        # YOLOv8/v11 for object detection
    torch torchvision \  # PyTorch (CPU; GPU version handled separately)
    opencv-python \
    numpy \
    scipy \
    matplotlib \
    transforms3d \       # 3D rotation math
    pyserial \           # Serial comms with microcontrollers
    smbus2 \             # I2C comms
    pyyaml \
    rclpy 2>/dev/null || true  # ROS 2 Python client lib (may already exist)

deactivate

# --- 4. Add venv activation alias to .bashrc ---
if ! grep -q "robocon_venv" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Robocon AI/Vision virtualenv" >> ~/.bashrc
    echo "alias robocon='source $HOME/robocon_venv/bin/activate'" >> ~/.bashrc
fi

# --- 5. Install micro-ROS agent (Docker-based, easiest method) ---
echo ""
echo "--- Installing micro-ROS agent via Docker ---"
if ! command -v docker &>/dev/null; then
    sudo apt install -y docker.io
    sudo usermod -aG docker $USER
    echo "⚠️  Added $USER to docker group. Log out and back in for this to take effect."
fi

# Pull the micro-ROS agent Docker image
docker pull microros/micro-ros-agent:jazzy

# Create a convenience launcher script
cat > "$HOME/Robocon/setup/run_microros_agent.sh" << 'EOF'
#!/bin/bash
# Usage: ./run_microros_agent.sh serial /dev/ttyUSB0 115200
# Usage: ./run_microros_agent.sh udp4 --port 8888
MODE=${1:-serial}
PORT=${2:-/dev/ttyUSB0}
BAUD=${3:-115200}

if [ "$MODE" = "serial" ]; then
    docker run -it --rm \
        --net=host \
        --privileged \
        -v /dev:/dev \
        microros/micro-ros-agent:jazzy \
        serial --dev "$PORT" -b "$BAUD"
elif [ "$MODE" = "udp4" ]; then
    docker run -it --rm \
        --net=host \
        microros/micro-ros-agent:jazzy \
        udp4 ${@:2}
fi
EOF
chmod +x "$HOME/Robocon/setup/run_microros_agent.sh"

echo ""
echo "✅ Python vision stack installed!"
echo "   Activate with: robocon   (alias added to .bashrc)"
echo ""
echo "✅ micro-ROS agent ready!"
echo "   Run serial: ./setup/run_microros_agent.sh serial /dev/ttyUSB0 115200"
echo "   Run UDP:    ./setup/run_microros_agent.sh udp4 --port 8888"
