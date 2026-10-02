#!/bin/bash
# =============================================================================
# ABU Robocon 2027 — Step 5: Robocon Workspace Bootstrap
# Creates the ROS 2 workspace structure and starter packages
# =============================================================================
set -e

source /opt/ros/jazzy/setup.bash

WORKSPACE="$HOME/robocon_ws"

echo "=============================================="
echo "  Bootstrapping Robocon ROS 2 Workspace"
echo "=============================================="

# --- 1. Create workspace ---
mkdir -p "$WORKSPACE/src"
cd "$WORKSPACE"

# --- 2. Create Transporter Robot (TR) package ---
cd "$WORKSPACE/src"
ros2 pkg create --build-type ament_python transporter_robot \
    --dependencies rclpy std_msgs geometry_msgs sensor_msgs nav_msgs

# --- 3. Create Builder Robot (BR) package ---
ros2 pkg create --build-type ament_python builder_robot \
    --dependencies rclpy std_msgs geometry_msgs sensor_msgs nav_msgs moveit_msgs action_msgs

# --- 4. Create vision package (block + Mustika detection) ---
ros2 pkg create --build-type ament_python robocon_vision \
    --dependencies rclpy sensor_msgs cv_bridge image_transport std_msgs

# --- 5. Create game logic / state machine package ---
ros2 pkg create --build-type ament_python robocon_game_manager \
    --dependencies rclpy std_msgs action_msgs

# --- 6. Create URDF/config package ---
ros2 pkg create --build-type ament_cmake robocon_description \
    --dependencies urdf xacro

# --- 7. Create simulation launch package ---
ros2 pkg create --build-type ament_cmake robocon_simulation \
    --dependencies ros_gz_sim ros_gz_bridge

# --- 8. Create shared messages/actions package ---
ros2 pkg create --build-type ament_cmake robocon_interfaces \
    --dependencies std_msgs geometry_msgs action_msgs rosidl_default_generators

# Add rosidl dependency to robocon_interfaces
cat >> "$WORKSPACE/src/robocon_interfaces/package.xml" << 'XML'
  <member_of_group>rosidl_interface_packages</member_of_group>
XML

# --- 9. Build the workspace ---
cd "$WORKSPACE"
colcon build --symlink-install --parallel-workers $(nproc)

# --- 10. Source workspace in .bashrc ---
if ! grep -q "robocon_ws" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Robocon ROS 2 Workspace" >> ~/.bashrc
    echo "source $WORKSPACE/install/setup.bash" >> ~/.bashrc
fi

echo ""
echo "✅ Robocon ROS 2 workspace created at: $WORKSPACE"
echo "   Packages created:"
echo "     - transporter_robot   (TR control)"
echo "     - builder_robot       (BR autonomous control)"
echo "     - robocon_vision      (block & Mustika detection)"
echo "     - robocon_game_manager (game state machine)"
echo "     - robocon_description (URDF robot models)"
echo "     - robocon_simulation  (Gazebo launch files)"
echo "     - robocon_interfaces  (custom ROS msgs/actions)"
echo ""
echo "   To start working: source ~/.bashrc && cd $WORKSPACE"
