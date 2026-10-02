#!/bin/bash
# =============================================================================
# ABU Robocon 2027 — Step 4: MATLAB R2024b Installation Guide
# University License (MathWorks Campus-Wide / TAH License)
# Ubuntu 24.04 LTS
# =============================================================================

# *** THIS SCRIPT CANNOT RUN MATLAB INSTALLATION AUTOMATICALLY. ***
# *** FOLLOW THE STEPS BELOW MANUALLY AFTER READING THIS GUIDE. ***

cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║          MATLAB R2024b — University License Installation Guide              ║
║                        Ubuntu 24.04 LTS                                    ║
╚══════════════════════════════════════════════════════════════════════════════╝

STEP 1: Get Your License from Your University
─────────────────────────────────────────────
1. Go to your university IT/software portal  OR
   Visit https://www.mathworks.com/academia/tah-portal.html
2. Search for your institution
3. Create a MathWorks account using your COLLEGE EMAIL (e.g., you@college.edu)
4. Associate the campus license to your account
5. Download the MATLAB Installer for Linux

STEP 2: Download MATLAB Installer
──────────────────────────────────
From https://www.mathworks.com/downloads/ (log in with your MathWorks account)
  - Select: R2024b
  - Platform: Linux (64-bit)
  - File: matlab_R2024b_Linux.zip  (~4 GB)

STEP 3: Install Required System Dependencies
─────────────────────────────────────────────
Run the following in terminal:

    sudo apt install -y \
        libglib2.0-0 \
        libxi6 \
        libxrender1 \
        libxtst6 \
        libgl1 \
        libglu1-mesa \
        libxrandr2 \
        libc6 \
        ca-certificates \
        wget

STEP 4: Run the Installer
──────────────────────────
    mkdir -p ~/matlab_installer
    unzip ~/Downloads/matlab_R2024b_Linux.zip -d ~/matlab_installer
    cd ~/matlab_installer
    sudo ./install          # Opens GUI installer

    In the installer:
      → Sign in with your MathWorks account
      → Choose "University License" (TAH)
      → Install to: /usr/local/MATLAB/R2024b
      → Select these toolboxes (REQUIRED for Robocon):
          ✅ MATLAB (base — always required)
          ✅ Simulink
          ✅ Simscape
          ✅ Simscape Multibody   ← mechanical simulation
          ✅ Robotics System Toolbox  ← ROS2 bridge + path planning
          ✅ Computer Vision Toolbox  ← block & Mustika detection
          ✅ Image Processing Toolbox
          ✅ Control System Toolbox   ← PID, state-space controllers
          ✅ Optimization Toolbox
          ✅ Statistics and Machine Learning Toolbox

STEP 5: Create Desktop Launcher and PATH
─────────────────────────────────────────
After installation, run:

    # Add MATLAB to PATH
    echo 'export PATH=/usr/local/MATLAB/R2024b/bin:$PATH' >> ~/.bashrc
    source ~/.bashrc

    # Create desktop shortcut
    sudo ln -sf /usr/local/MATLAB/R2024b/bin/matlab /usr/local/bin/matlab

    # Test installation
    matlab -nojvm -nodisplay -r "ver; exit"

STEP 6: Configure ROS 2 Bridge in MATLAB
──────────────────────────────────────────
Once MATLAB is installed, open it and run:

    >> ros2 list   % should list your ROS2 nodes if ROS2 is sourced
    
    % Configure ROS domain (same as your ROS_DOMAIN_ID in .bashrc)
    >> setenv('ROS_DOMAIN_ID', '42')

STEP 7: Recommended MATLAB Add-Ons
────────────────────────────────────
From MATLAB's Add-On Explorer (Home → Add-Ons):
  • UAV Toolbox                  — for drone-like trajectory planning
  • Lidar Toolbox                — if you add LiDAR later
  • Deep Learning Toolbox        — for advanced vision

TOOLBOX SUMMARY FOR ROBOCON 2027:
───────────────────────────────────
  Simscape Multibody  → Simulate robot arm kinematics (BR stacking arm)
  Robotics Toolbox    → SLAM, path planning, ROS2 publish/subscribe from MATLAB  
  Computer Vision TB  → Prototype block and Mustika detection algorithms
  Control System TB   → Design PID controllers for motors (export to embedded C)
  Simulink            → Model-Based Design → auto-generate C code for STM32

EOF

echo ""
echo "📋 MATLAB installation guide printed above."
echo "   Once installed, verify with: matlab -nojvm -nodisplay -r \"ver; exit\""
