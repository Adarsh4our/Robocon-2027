#!/bin/bash
# =============================================================================
# ABU Robocon 2027 — Step 2: Gazebo Harmonic Installation
# Compatible with ROS 2 Jazzy on Ubuntu 24.04
# =============================================================================
set -e

echo "=============================================="
echo "  Gazebo Harmonic — 3D Physics Simulator"
echo "=============================================="

# --- 1. Add Gazebo APT Repository ---
sudo apt install -y curl lsb-release gnupg
sudo curl -sSL https://packages.osrfoundation.org/gazebo.gpg \
    -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] \
    http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null

sudo apt update

# --- 2. Install Gazebo Harmonic ---
sudo apt install -y gz-harmonic

# --- 3. Install ROS-Gazebo Bridge (ros_gz) ---
sudo apt install -y \
    ros-jazzy-ros-gz \
    ros-jazzy-ros-gz-sim \
    ros-jazzy-ros-gz-bridge \
    ros-jazzy-ros-gz-image

echo ""
echo "✅ Gazebo Harmonic installed successfully!"
echo "   Test with: gz sim shapes.sdf"
echo "   ROS bridge: ros2 launch ros_gz_sim gz_sim.launch.py"
