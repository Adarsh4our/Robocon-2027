#!/bin/bash
# =============================================================================
# ABU Robocon 2027 — Step 1: ROS 2 Jazzy Installation
# Ubuntu 24.04 LTS (Noble Numbat)
# =============================================================================
set -e

echo "=============================================="
echo "  ROS 2 Jazzy Jalisco — Full Desktop Install"
echo "=============================================="

# --- 1. Locale Setup ---
sudo apt update && sudo apt install -y locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

# --- 2. Add ROS 2 APT Repository ---
sudo apt install -y software-properties-common curl
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
    http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" \
    | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

# --- 3. Install ROS 2 Jazzy Desktop (full GUI + tools) ---
sudo apt update
sudo apt upgrade -y
sudo apt install -y ros-jazzy-desktop

# --- 4. Install ROS 2 Dev Tools ---
sudo apt install -y \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool \
    ros-dev-tools \
    python3-argcomplete

# --- 5. Initialize rosdep ---
sudo rosdep init 2>/dev/null || echo "rosdep already initialized"
rosdep update

# --- 6. Source ROS 2 in .bashrc ---
if ! grep -q "source /opt/ros/jazzy/setup.bash" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# ROS 2 Jazzy" >> ~/.bashrc
    echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
    echo "export ROS_DOMAIN_ID=42   # Unique ID for your team's network" >> ~/.bashrc
    echo "export RMW_IMPLEMENTATION=rmw_fastrtps_cpp" >> ~/.bashrc
    echo 'source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash 2>/dev/null || true' >> ~/.bashrc
fi

# --- 7. Install Nav2 (autonomous navigation stack for BR) ---
sudo apt install -y \
    ros-jazzy-navigation2 \
    ros-jazzy-nav2-bringup \
    ros-jazzy-nav2-map-server

# --- 8. Install MoveIt2 (arm motion planning for BR's block-stacking arm) ---
sudo apt install -y ros-jazzy-moveit

# --- 9. Install useful extras ---
sudo apt install -y \
    ros-jazzy-tf2-tools \
    ros-jazzy-rqt \
    ros-jazzy-rqt-common-plugins \
    ros-jazzy-rviz2 \
    ros-jazzy-ros2-control \
    ros-jazzy-ros2-controllers \
    ros-jazzy-joint-state-publisher \
    ros-jazzy-robot-state-publisher \
    ros-jazzy-xacro \
    ros-jazzy-image-transport \
    ros-jazzy-cv-bridge

echo ""
echo "✅ ROS 2 Jazzy installed successfully!"
echo "   Restart your terminal or run: source ~/.bashrc"
echo "   Then verify with: ros2 --version"
