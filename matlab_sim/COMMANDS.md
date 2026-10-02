# MATLAB Simulation Commands & Reference Guide
## ABU Robocon 2027 · Builder Robot (BR) FSM

This directory contains the complete Simulink/Stateflow FSM simulation and performance analytics.

---

### 📂 File Structure

| File | Purpose | Notes |
|---|---|---|
| `BR_FSM_Sim.slx` | **Main Simulink & Stateflow Model** | 21 states, visual layout locked 🔒 |
| `test_br_scenario.m` | **Match Simulator Script** | Simulates 180s match, logs signals, plots timeline |
| `analyze_br_performance.m` | **Strategy & Power Analyzer** | Computes speed budget & sensor power savings |
| `br_fsm_timeline.png` | **Timeline Plot** | State progression, sensor mask, motor commands |
| `br_performance_dashboard.png` | **Executive Dashboard** | 4-panel speed budget & power management chart |
| `build_br_fsm.m` | *Model Builder Script* | (DO NOT RUN unless resetting canvas layout) |

---

### ⚡ MATLAB Command Window Quick Reference

#### 1. Open the Visual Stateflow Canvas
To open the Simulink model and explore the 21 states:
```matlab
cd('/home/adarsh4our/Robocon/matlab_sim')
open_system('BR_FSM_Sim')
```
*(Double-click on `BR_Autonomous_Brain` to view the Stateflow chart)*

---

#### 2. Run the 180-Second Match Simulation
To run the full match simulation and plot the state progression:
```matlab
cd('/home/adarsh4our/Robocon/matlab_sim')
test_br_scenario
```
* Generates: `br_fsm_timeline.png`
* Simulates: 4-step stair ascent, Tower 1, Tower 2 (Shared Area), Sanctuary Unlock, and Mustika enshrinement (+250 Pts).

---

#### 3. Run Speed Budget & Power Management Analysis
To analyze time allocation and sensor energy savings:
```matlab
cd('/home/adarsh4our/Robocon/matlab_sim')
analyze_br_performance
```
* Generates: `br_performance_dashboard.png`
* Outputs:
  * Total match completion time and safety margin.
  * Time spent in Driving, Stair Climbing, Vision Servoing, Manipulation, and Waiting.
  * Sensor duty cycles and Watt-hour energy reduction vs. unmanaged baselines.
