# Reference Catalog: robocon_sim & ABU-Robocon-2027-Gazebo
> **Purpose:** Technology audit of two reference projects. Use this as a menu of tools and ideas when building your own simulator from scratch.

---

## 1. Programming Languages & Build Systems

| Tool | Used In | What It Does |
|---|---|---|
| **Python 3.12** | `omni_sim` (everything) | Core simulation, control, planning, sensors |
| **XML / SDF 1.7** | Gazebo (`model.sdf`, `world`) | Describes 3D physics scene: geometry, materials, physics params |
| **CMake + ament_cmake** | Gazebo (`CMakeLists.txt`, `package.xml`) | ROS 2 package build system |
| **YAML** | `omni_sim` (all config files) | Human-readable config: robot specs, field geometry, scenario params |
| **TOML** | `omni_sim` (`pyproject.toml`) | Python package metadata & dependencies |
| **Bash** | Gazebo (`build.sh`) | Build automation script |

---

## 2. Python Libraries Used

### Scientific / Numerical Core
| Library | Why It's Used | Key Usage in omni_sim |
|---|---|---|
| `numpy` | Fast array math | Motor state vectors, Jacobian matrix ops, all physics |
| `scipy.signal` | Signal processing & filter design | DOB filter discretization via `cont2discrete()` (Tustin method) |
| `scipy.ndimage` | Image processing on grids | Occupancy grid distance transforms for path cost fields |

### Visualization
| Library | Why It's Used | Key Usage |
|---|---|---|
| `matplotlib` | 2D plotting & animation | Live robot viewer, Bode plots, sweep result plots |
| `PIL (Pillow)` | Image I/O | Reading/writing PGM map files (`.pgm` + `.yaml`) |
| `seaborn` *(optional)* | Plot styling | Dark theme for result charts (gracefully skipped if absent) |

### Config & File Formats
| Library | Why It's Used | Key Usage |
|---|---|---|
| `pyyaml` | YAML loading | Loading scenario, field, and sensor configs |
| `ruamel.yaml` | Comment-preserving YAML | Mechanism layer: read/write config without losing `# comments` |

### ROS 2 Interfaces (optional wrapper only)
| Library | Why It's Used |
|---|---|
| `rclpy` | ROS 2 Python client — node lifecycle, pub/sub |
| `sensor_msgs.msg` | `LaserScan`, `Imu`, `JointState` message types |
| `nav_msgs.msg` | `Odometry` message type |
| `geometry_msgs.msg` | `Twist`, `WrenchStamped` |
| `tf2_ros` | Coordinate frame transforms (`map → odom → base_link`) |
| `std_msgs`, `std_srvs` | Basic types & services (`/sim/reset`, `/sim/pause`) |
| `launch`, `launch_ros` | ROS 2 Python launch system |

### Testing
| Library | Why It's Used |
|---|---|
| `pytest` | Unit & acceptance test runner |

### Python Standard Library (key stdlib used)
`dataclasses`, `pathlib`, `argparse`, `multiprocessing`, `heapq`, `json`, `csv`, `math`, `typing`, `collections`, `itertools`, `functools`, `hashlib`, `io`, `unicodedata`

---

## 3. ROS 2 Concepts Used

| Concept | Gazebo Project | omni_sim |
|---|---|---|
| **Packages** (`package.xml`, `CMakeLists.txt`) | ✅ `robocon_2027_gazebo` | ✅ `omni_sim_ros` |
| **Launch files** (`.launch.py`) | ✅ Launches Gazebo world | ✅ Launches sim node |
| **Topics (Pub/Sub)** | Via `gazebo_ros` plugins | `/scan`, `/odom`, `/imu`, `/cmd_vel`, `/clock` |
| **Services** | ❌ None | `/sim/reset`, `/sim/pause` |
| **TF Transforms** | Gazebo handles internally | Published by `sim_node.py` |
| **`use_sim_time`** | ❌ | ✅ All nodes use sim clock |
| **`colcon` build** | ✅ | ✅ |
| **`ament_cmake`** | ✅ | ✅ |
| **ROS Distro** | Humble (Ubuntu 22.04) ⚠️ | Jazzy (Ubuntu 24.04) ✅ installed |

---

## 4. Gazebo-Specific Technologies (from Gazebo project)

| Technology | What It Is | Details |
|---|---|---|
| **Gazebo Classic** | 3D robot simulator | The older `gazebo` binary (not Ignition/Fortress) |
| **SDF v1.7** | Simulation Description Format | XML file describing world: physics, models, lights, scenes |
| **STL mesh files** | 3D triangle-mesh geometry | Used for both collision (1 unified) and visuals (35 colored parts) |
| **ODE physics** | Open Dynamics Engine | Gazebo's built-in rigid-body solver; `max_step_size=0.001s` |
| **`gazebo_ros` package** | ROS↔Gazebo bridge | Publishes Gazebo state as ROS topics |
| **`model.config`** | Gazebo model metadata | Name, version, author for the Gazebo model database |
| **`GAZEBO_MODEL_PATH`** | Env variable | Tells Gazebo where to find model folders |
| **Coordinate convention** | CAD: mm, Y-up → SDF: m, Z-up | Field scaled by `0.001`, rotated `π/2` around X |

---

## 5. Algorithms & Control Theory

### Control Algorithms (omni_sim)
| Algorithm | File | What It Does |
|---|---|---|
| **PID Controller** | `control/pid.py` | Tracks motor speed reference; computes `tau_pid` |
| **Disturbance Observer (DOB)** | `control/dob.py` | Estimates unknown forces; cancels them from motor command |
| **Tustin Discretization** | `control/dob.py` | Converts continuous-time filter `Q(s)·P_n⁻¹(s)` to discrete IIR filter |
| **Direct Form II IIR Filter** | `control/dob.py` | Memory-efficient digital filter implementation |
| **Butterworth Low-Pass Filter** | `control/dob.py` | 1st or 2nd order Q(s) filter for DOB |
| **Trajectory Following** | `control/trajectory.py` | Body-frame PID + feedforward on planned path |

### Numerical Integration
| Algorithm | File | What It Does |
|---|---|---|
| **RK4 (Runge-Kutta 4th order)** | `integrator.py` | Fixed-step integration of all ODEs — deterministic, no `solve_ivp` |
| **Zero-Order Hold (ZOH)** | `clock.py` | Motor command held constant between control ticks |
| **Multi-Rate Clock** | `clock.py` | `dt_sim` (integration) < `dt_motor` (control) < `dt_nav` (planning) |

### Path Planning
| Algorithm | File | What It Does |
|---|---|---|
| **A* Search** | `planning/grid_planner.py` | Finds shortest path on inflated cost grid |
| **Dijkstra cost field** | `planning/cost_field.py` | Distance transform: each cell stores distance to nearest obstacle |
| **Line-of-Sight Shortcutting** | `planning/shortcut.py` | Prunes unnecessary A* waypoints via raycasting |
| **Clamped Cubic B-Spline** | `planning/smooth.py` | Smooths polyline into C² curve; stays inside convex hull (no wall overshoot) |
| **2-Pass Velocity Profile** | `planning/corner.py` | Forward/backward passes: limit speed by curvature κ → max lateral accel |
| **Orientation planning** | `planning/orientation.py` | Headings along path for omni robot |

### Sensor Simulation
| Algorithm | File | What It Does |
|---|---|---|
| **DDA Raycasting** | `env/raycast.py` | Vectorized over all beams: Digital Differential Analyzer on grid |
| **Encoder Quantization** | `sensors/encoder.py` | Discretizes wheel angle to integer ticks (CPR) |
| **IMU Noise Model** | `sensors/imu.py` | Gyro bias + Gaussian noise, rate FIFO with latency |
| **LiDAR Noise Model** | `sensors/lidar.py` | Range noise + dropout + latency FIFO |

### State Estimation
| Algorithm | File | What It Does |
|---|---|---|
| **Wheel Odometry** | `plant/odometry.py` | Integrates encoder ticks through inverse Jacobian |
| **Monte Carlo Localization (MCL)** | `localization/mcl.py` | Particle filter: LiDAR scan matching against known map |
| **Likelihood Field** | `localization/likelihood_field.py` | Pre-computed nearest-obstacle distance for fast particle scoring |

### Robot Kinematics / Dynamics
| Concept | File | Details |
|---|---|---|
| **Omni-wheel Jacobian** | `plant/jacobian.py` | Static 4×3 map: body twist ↔ wheel speeds / forces |
| **Virtual work principle** | `plant/jacobian.py` | `J^T` maps wheel forces → body wrench |
| **3-DOF Rigid Body** | `plant/body.py` | Planar `x, y, θ` dynamics with mass matrix |
| **Motor true model** | `plant/motor.py` | Back-EMF, winding resistance, Coulomb friction, cogging torque |
| **Nominal model** | `plant/nominal.py` | Simplified `1/(Jn·s + Bn)` — what DOB assumes |
| **Torque-speed envelope** | `simulator.py` | Clamps available torque: `τ_avail(ω) = τ_stall·(1 - |ω|/ω_noload)` |

---

## 6. File Formats & Data Exchange

| Format | Used By | Purpose |
|---|---|---|
| **YAML** | omni_sim (configs) | Robot description, field geometry, scenario parameters |
| **TOML** | omni_sim (`pyproject.toml`) | Package metadata, dependencies, test config |
| **PGM + YAML** | omni_sim (maps) | ROS-compatible occupancy grid maps (nav2 format) |
| **CSV** | omni_sim (results) | Time-series simulation logs for offline analysis |
| **JSON** | omni_sim (web dashboard) | `/sim/scene` topic payload for browser rendering |
| **SDF (XML)** | Gazebo (`model.sdf`, `.world`) | 3D physics scene description |
| **STL** | Gazebo (meshes) | Binary triangle mesh — collision + visual geometry |
| **GIF** | omni_sim (`live_view.gif`) | Animated headless robot demo |

---

## 7. Design Patterns & Architecture Decisions

| Pattern | Where Used | Why |
|---|---|---|
| **True plant vs. Nominal model separation** | `plant/motor.py` vs `plant/nominal.py` | DOB needs the gap between real and modeled; never merge |
| **Strict layer dependencies** | All of omni_sim | `gui → core`, `mechanism → plant` (never reverse) |
| **`@dataclass` config objects** | Every module | YAML loads into typed Python dataclasses; no magic strings |
| **Explicit `numpy.random.Generator`** | `disturbance.py`, sensors | No global RNG → same seed = bit-identical run |
| **Fixed-step RK4 (no `solve_ivp`)** | `integrator.py` | Variable-step breaks ZOH sync and reproducibility |
| **Static field layer slicing** | `field/slicer.py` | One field YAML → multiple occupancy grids per layer (ground/L1/L2) |
| **Editable Python install** | `pyproject.toml` | `pip install -e` allows live code editing without reinstall |
| **Provenance tagging in YAML** | `config/field/robocon2027.yaml` | `[R]` rulebook / `[F]` estimated / `[A]` assumed — every dimension sourced |
| **Comment-preserving YAML round-trip** | `mechanism/yaml_rt.py` | Generated configs don't destroy hand-written comments |

---

## 8. Tools & Dev Infrastructure

| Tool | Used By | Purpose |
|---|---|---|
| **`pytest`** | omni_sim | 18 acceptance tests + 150+ unit/integration tests |
| **`colcon`** | Both | ROS 2 workspace build tool |
| **`pip install -e`** | omni_sim | Editable local package install |
| **`setup_env.py`** | omni_sim | Idempotent venv + deps + VS Code setup script |
| **`multiprocessing`** | omni_sim sweeps | Parallel parameter sweeps across CPU cores |
| **VS Code** | omni_sim (`.vscode/`) | Recommended editor with extensions list |
| **Git** | Both | Version control |

---

## 9. Field Representation Approaches

| Approach | Gazebo Project | omni_sim |
|---|---|---|
| **Source** | CAD → STEP → STL meshes | Rulebook numbers → YAML → Python |
| **Geometry format** | Binary STL triangle mesh | Height-annotated 2D primitives (`Box`, `Cylinder`, `Segment`) |
| **Collision** | ODE mesh collision (3D) | Analytical polygon-polygon / polygon-circle distance |
| **Navigation grid** | Not provided | PGM occupancy grid, 20mm/cell resolution |
| **3D awareness** | Full 3D | Multi-layer 2D (ground, L1, L2 as separate grids) |
| **Ramp/slope** | Static collision mesh | `SlopeField` → gravity force vector injected into body dynamics |

---

## 10. Minimum Tech Stack to Build Yours From Scratch

### Must-Have (core sim)
- `Python 3.11+` · `numpy` · `scipy` · `pyyaml`
- **RK4 integrator** for physics
- **Motor dynamics model** (true plant with back-EMF + friction)
- **Omni-wheel Jacobian** (4×3 matrix)
- **PID controller**
- **2D Occupancy grid** (numpy array map)
- **A\* path planner**
- **YAML configs** for robot + field
- **CSV logging** for results
- **`pytest`** test suite

### Nice-to-Have (from references)
- **DOB** — Disturbance Observer for robust motor control
- **B-spline path smoother** — smooth trajectories without wall overshoot
- **DDA raycasting LiDAR** — fast 2D sensor simulation
- **MCL Particle filter** — localization against a map
- **ROS 2 Jazzy wrapper** (`rclpy`) — topic publishing for RViz / nav2
- **`matplotlib`** live viewer
- **Multi-rate clock** (`dt_sim` < `dt_motor` < `dt_nav`)
- **`ruamel.yaml`** — comment-preserving config generation

### If You Want 3D Visualization
- **Gazebo Harmonic** (Jazzy-compatible — NOT Classic)
- **STL meshes** of field (reuse the 35 parts from the Gazebo reference)
- **SDF world file** with physics + lighting
- **`gz_ros2_control`** or **`ros_gz_bridge`** for Jazzy
