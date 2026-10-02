%% build_br_fsm.m  (v3 — FULL REFACTOR with stair sub-states)
%  -----------------------------------------------------------------------
%  ABU Robocon 2027 — Builder Robot (BR) Finite State Machine
%  
%  Hardware:
%    Drivetrain : Tri-wheel rocker stair climber (150mm steps, 10 steps max)
%    Gripper    : Mechanical clamp / jaws (confirmed)
%    Sensors    : 2D LiDAR, Depth Camera, IMU, Wheel Encoders, Clamp limit switches
%    Lifting    : Generic vertical lift arm (multi-stage TBD)
%
%  Stair climbing sub-states (new):
%    NAV_TO_STAIR → ENGAGE_STEP → CLIMBING → LEVEL_REACHED → [next state]
%
%  Strategy:
%    Tower 1 → Team L1 exclusive zone
%    Tower 2 → L1 Shared Area (unlocks Sanctuary Mandate)
%
%  Layout: Clean S-curve snake (4 columns, 5 rows + side lane for recovery)
%  -----------------------------------------------------------------------

modelName = 'BR_FSM_Sim';
if bdIsLoaded(modelName), close_system(modelName, 0); end
if exist([modelName '.slx'], 'file'), delete([modelName '.slx']); end

new_system(modelName);
open_system(modelName);
set_param(modelName, ...
    'StopTime', '180', 'FixedStep', '0.1', ...
    'Solver', 'FixedStepDiscrete', ...
    'SignalLogging', 'on', 'SignalLoggingName', 'logsout');

%% ======  STATEFLOW CHART  ======
chartPath = [modelName '/BR_Autonomous_Brain'];
add_block('sflib/Chart', chartPath, 'Position', [280 30 780 720]);
rt    = sfroot;
chart = rt.find('-isa', 'Stateflow.Chart', '-and', 'Path', chartPath);
chart.ChartUpdate = 'DISCRETE';
chart.SampleTime  = '0.1';

%% ======  SENSOR BITMASK LEGEND  ======
% Bit 0 (1)  : 2D LiDAR
% Bit 1 (2)  : IMU (pitch / orientation)
% Bit 2 (4)  : Wheel Encoders
% Bit 3 (8)  : Depth Camera (block/spot/pillar detection)
% Bit 4 (16) : Clamp Limit Switches (jaw open/close confirm)
%
% Common combos:
%   NAVIGATION   = LiDAR + IMU + Encoders         = 1+2+4 = 7
%   VISUAL_ALIGN = Depth Camera + LiDAR           = 8+1   = 9
%   GRIP_CONFIRM = Clamp switches + Encoders       = 16+4  = 20
%   STAIR_CLIMB  = IMU + Encoders + LiDAR         = 7     (same as nav)
%   PLACE_BLOCK  = Clamp switches + Depth Cam     = 16+8  = 24
%   ENSHRINE     = Depth Camera + Clamp switches  = 24
%   ALL_OFF      = 0

%% ======  INPUTS  ======
inputDefs = {
    % Navigation
    'start_buzzer',        'Match start signal (0/1)'
    'stair_detected',      'LiDAR: stair edge detected within 20cm (0/1)'
    'step_engaged',        'IMU: front wheel pitched up on riser (0/1)'
    'step_climbed',        'IMU+Enc: pitch spike + encoder tick = 1 step done (0/1)'
    'all_steps_done',      'Encoder: total step count reached target level (0/1)'
    'transfer_reached',    'Encoder: arrived at Transfer Area position (0/1)'
    'build_zone_reached',  'Encoder: arrived at target build zone (0/1)'
    'back_at_transfer',    'Encoder: returned to Transfer Area (0/1)'
    % Sensing
    'block_in_zone',       'Depth Cam: block detected in Transfer Area (0/1)'
    'block_color',         'Depth Cam: 1=Earth(Red/Blue) 2=Sky (for tower sequencing)'
    'spot_detected',       'Depth Cam: green 500x500mm build spot found (0/1)'
    'spot_aligned',        'Depth Cam: alignment error < 5mm (0/1)'
    % Gripper
    'clamp_closed',        'Limit switch: both jaws fully closed on block (0/1)'
    'clamp_released',      'Limit switch: jaws fully open, block free (0/1)'
    % Tower tracking
    'towers_built',        'Counter: total complete towers (Earth+Earth+Sky)'
    'shared_tower_built',  'Flag: 1 if tower placed in shared area (0/1)'
    % 'return_ready' removed — covered by back_at_transfer signal
    % Mustika
    'mustika_in_zone',     'Depth Cam: Mustika (yellow/blue volleyball) detected (0/1)'
    'mustika_clamped',     'Limit switch: jaws closed around volleyball (0/1)'
    'l2_reached',          'Encoder+IMU: arrived at Level 2 (0/1)'
    'pillar_aligned',      'Depth Cam: aligned over Central Pillar receptacle (0/1)'
    'mustika_placed',      'Depth Cam: Mustika seated, no longer in gripper (0/1)'
    % Safety
    'sensor_fault',        'Watchdog: any sensor timeout or OOB reading (0/1)'
    'retry_ok',            'Encoder: BR returned to Retry Zone safely (0/1)'
    'match_time',          'System clock: match elapsed time 0-180s'
};

for i = 1:size(inputDefs,1)
    d = Stateflow.Data(chart);
    d.Name = inputDefs{i,1}; d.Scope = 'Input';
    d.Props.Type.Method = 'Built-in';
    d.Props.Type.Primitive = 'double';
    d.Description = inputDefs{i,2};
end

%% ======  OUTPUTS  ======
outputDefs = {
    'current_state',  'State ID 1-22'
    'active_sensors', 'Sensor bitmask (see legend)'
    'drive_cmd',      '0=STOP 1=CLIMB_STAIR 2=SCAN 3=FINE_POS 4=DESCEND 5=DRIVE_FWD'
    'gripper_cmd',    '0=IDLE 1=CLOSE_CLAMP 2=OPEN_CLAMP 3=HOLD'
    'arm_cmd',        '0=STOW 1=EXTEND 2=LOWER 3=LIFT 4=HOVER'
    'status_msg',     '-1=FAULT 0=STANDBY 1-20=PROGRESS 99=VICTORY'
};

for i = 1:size(outputDefs,1)
    d = Stateflow.Data(chart);
    d.Name = outputDefs{i,1}; d.Scope = 'Output';
    d.Props.Type.Method = 'Built-in';
    d.Props.Type.Primitive = 'double';
    d.Description = outputDefs{i,2};
end

%% ======  STATE DEFINITIONS  ======
% S-curve layout:
%   Row 1 (L→R): IDLE → NAV_TO_STAIR_1 → ENGAGE_STEP_1 → CLIMBING_1
%   Row 2 (R→L): WAIT_FOR_BLOCK ← TRANSFER_READY ← LEVEL_REACHED_1 ←
%   Row 3 (L→R): PICK_BLOCK → DRIVE_TO_TOWER_AREA → DETECT_GREEN_SPOT → ALIGN_TO_SPOT
%   Row 4 (R→L): CHECK_SANCTUARY ← PLACE_BLOCK ←
%   Row 5 (L→R): RETURN_TO_TRANSFER → NAV_STAIR_DOWN → WAIT_FOR_MUSTIKA → PICK_MUSTIKA
%   Row 6 (R→L): MATCH_COMPLETE ← ENSHRINE_MUSTIKA ← ALIGN_PILLAR ← NAV_TO_L2
%   Side col 5:  RECOVERY_RETRY
%
% { Name, ID, {entry actions}, gridCol, gridRow }

stateDefs = {

  % ===== ROW 1: Startup → Climb to Transfer Area =====
  'IDLE', 1, ...
    {'current_state=1;','active_sensors=0;','drive_cmd=0;','gripper_cmd=0;','arm_cmd=0;','status_msg=0;'}, ...
    1,1

  'NAV_TO_STAIR_1', 2, ...
    {'current_state=2;','active_sensors=7;','drive_cmd=5;','gripper_cmd=0;','arm_cmd=0;','status_msg=1;'}, ...
    2,1

  'ENGAGE_STEP_1', 3, ...
    {'current_state=3;','active_sensors=7;','drive_cmd=1;','gripper_cmd=0;','arm_cmd=0;','status_msg=2;'}, ...
    3,1

  'CLIMBING_L1', 4, ...
    {'current_state=4;','active_sensors=7;','drive_cmd=1;','gripper_cmd=0;','arm_cmd=0;','status_msg=3;'}, ...
    4,1

  % ===== ROW 2: Level reached → Wait for block =====
  'LEVEL_REACHED_L1', 5, ...
    {'current_state=5;','active_sensors=3;','drive_cmd=0;','gripper_cmd=0;','arm_cmd=0;','status_msg=4;'}, ...
    4,2

  'TRANSFER_READY', 6, ...
    {'current_state=6;','active_sensors=9;','drive_cmd=5;','gripper_cmd=0;','arm_cmd=1;','status_msg=5;'}, ...
    3,2

  'WAIT_FOR_BLOCK', 7, ...
    {'current_state=7;','active_sensors=9;','drive_cmd=0;','gripper_cmd=0;','arm_cmd=1;','status_msg=6;'}, ...
    2,2

  % ===== ROW 3: Pick block → Navigate to build spot =====
  'PICK_BLOCK', 8, ...
    {'current_state=8;','active_sensors=20;','drive_cmd=0;','gripper_cmd=1;','arm_cmd=3;','status_msg=7;'}, ...
    1,2

  'DRIVE_TO_TOWER_AREA', 9, ...
    {'current_state=9;','active_sensors=7;','drive_cmd=5;','gripper_cmd=3;','arm_cmd=4;','status_msg=8;'}, ...
    1,3

  'DETECT_GREEN_SPOT', 10, ...
    {'current_state=10;','active_sensors=9;','drive_cmd=2;','gripper_cmd=3;','arm_cmd=4;','status_msg=9;'}, ...
    2,3

  'ALIGN_TO_SPOT', 11, ...
    {'current_state=11;','active_sensors=9;','drive_cmd=3;','gripper_cmd=3;','arm_cmd=4;','status_msg=10;'}, ...
    3,3

  'PLACE_BLOCK', 12, ...
    {'current_state=12;','active_sensors=24;','drive_cmd=0;','gripper_cmd=2;','arm_cmd=2;','status_msg=11;'}, ...
    4,3

  % ===== ROW 4: Check sanctuary → Return =====
  'CHECK_SANCTUARY', 13, ...
    {'current_state=13;','active_sensors=0;','drive_cmd=0;','gripper_cmd=0;','arm_cmd=0;','status_msg=12;'}, ...
    4,4

  'RETURN_TO_TRANSFER', 14, ...
    {'current_state=14;','active_sensors=7;','drive_cmd=4;','gripper_cmd=0;','arm_cmd=0;','status_msg=13;'}, ...
    3,4

  % ===== ROW 5: Mustika sequence =====
  'WAIT_FOR_MUSTIKA', 15, ...
    {'current_state=15;','active_sensors=9;','drive_cmd=0;','gripper_cmd=0;','arm_cmd=1;','status_msg=14;'}, ...
    2,4

  'PICK_MUSTIKA', 16, ...
    {'current_state=16;','active_sensors=24;','drive_cmd=0;','gripper_cmd=1;','arm_cmd=3;','status_msg=15;'}, ...
    1,4

  'NAV_TO_L2', 17, ...
    {'current_state=17;','active_sensors=7;','drive_cmd=1;','gripper_cmd=3;','arm_cmd=0;','status_msg=16;'}, ...
    1,5

  'ALIGN_TO_PILLAR', 18, ...
    {'current_state=18;','active_sensors=9;','drive_cmd=3;','gripper_cmd=3;','arm_cmd=4;','status_msg=17;'}, ...
    2,5

  'ENSHRINE_MUSTIKA', 19, ...
    {'current_state=19;','active_sensors=24;','drive_cmd=0;','gripper_cmd=2;','arm_cmd=2;','status_msg=18;'}, ...
    3,5

  'MATCH_COMPLETE', 20, ...
    {'current_state=20;','active_sensors=0;','drive_cmd=0;','gripper_cmd=0;','arm_cmd=0;','status_msg=99;'}, ...
    4,5

  % ===== SIDE LANE: Recovery =====
  'RECOVERY_RETRY', 21, ...
    {'current_state=21;','active_sensors=7;','drive_cmd=4;','gripper_cmd=2;','arm_cmd=0;','status_msg=-1;'}, ...
    5,3
};

%% ======  BUILD STATES  ======
boxW=240; boxH=145; gapX=55; gapY=45; startX=30; startY=40;
numStates = size(stateDefs,1);
stateObjs = cell(numStates,1);

for i = 1:numStates
    s = Stateflow.State(chart);
    s.Name = stateDefs{i,1};
    cmds = stateDefs{i,3};
    s.LabelString = sprintf('%s\nentry:\n%s', stateDefs{i,1}, sprintf('  %s\n', cmds{:}));
    col = stateDefs{i,4}; row = stateDefs{i,5};
    s.Position = [startX+(col-1)*(boxW+gapX), startY+(row-1)*(boxH+gapY), boxW, boxH];
    stateObjs{i} = s;
end

findState = @(name) stateObjs{find(strcmp(stateDefs(:,1), name), 1)};

%% ======  DEFAULT TRANSITION  ======
dt = Stateflow.Transition(chart);
dt.Destination = findState('IDLE');
dt.DestinationOClock = 0;
idlePos = findState('IDLE').Position;
dt.SourceEndPoint = [idlePos(1)+boxW/2, idlePos(2)-22];

%% ======  TRANSITIONS  ======
% { From, To, Condition, srcClock, dstClock }
transDefs = {

  % === ROW 1: Startup / Climb to L1 (Explicit Step-by-Step Loop) ===
  'IDLE',           'NAV_TO_STAIR_1', '[start_buzzer == 1]',                              3, 9
  'NAV_TO_STAIR_1', 'ENGAGE_STEP_1',  '[stair_detected == 1]',                            3, 9
  'ENGAGE_STEP_1',  'CLIMBING_L1',    '[step_engaged == 1]',                              3, 9
  'CLIMBING_L1',    'ENGAGE_STEP_1',  '[step_climbed == 1 && all_steps_done == 0]',       0, 0
  'CLIMBING_L1',    'LEVEL_REACHED_L1','[all_steps_done == 1]',                           6, 0

  % === ROW 2: Level reached → Transfer Area ===
  'LEVEL_REACHED_L1','TRANSFER_READY','[transfer_reached == 1]',                          9, 3
  'TRANSFER_READY', 'WAIT_FOR_BLOCK', '[block_color > 0]',                                9, 3

  % === ROW 2→3: Block detected → Pick ===
  'WAIT_FOR_BLOCK', 'PICK_BLOCK',     '[block_in_zone == 1 && block_color > 0]',          9, 3

  % === ROW 3: Pick → Build ===
  'PICK_BLOCK',           'DRIVE_TO_TOWER_AREA','[clamp_closed == 1]',                            6, 0
  'DRIVE_TO_TOWER_AREA',  'DETECT_GREEN_SPOT',  '[build_zone_reached == 1]',                      3, 9
  'DETECT_GREEN_SPOT',    'ALIGN_TO_SPOT',      '[spot_detected == 1]',                           3, 9
  'ALIGN_TO_SPOT',        'PLACE_BLOCK',        '[spot_aligned == 1]',                            3, 9

  % === ROW 4: Place → Check ===
  'PLACE_BLOCK',    'CHECK_SANCTUARY','[clamp_released == 1]',                            6, 0

  % === ROW 4: Sanctuary branches ===
  'CHECK_SANCTUARY','RETURN_TO_TRANSFER','[towers_built < 2 || shared_tower_built == 0]', 9, 3
  'RETURN_TO_TRANSFER','WAIT_FOR_BLOCK','[back_at_transfer == 1]',                        0, 6

  % === Sanctuary unlocked → Mustika ===
  'CHECK_SANCTUARY','WAIT_FOR_MUSTIKA','[towers_built >= 2 && shared_tower_built == 1]',  9, 9

  % === ROW 5: Mustika retrieval ===
  'WAIT_FOR_MUSTIKA','PICK_MUSTIKA',  '[mustika_in_zone == 1]',                           9, 3
  'PICK_MUSTIKA',   'NAV_TO_L2',     '[mustika_clamped == 1]',                            6, 0
  'NAV_TO_L2',      'ALIGN_TO_PILLAR','[l2_reached == 1]',                               3, 9
  'ALIGN_TO_PILLAR','ENSHRINE_MUSTIKA','[pillar_aligned == 1]',                           3, 9
  'ENSHRINE_MUSTIKA','MATCH_COMPLETE','[mustika_placed == 1]',                            3, 9

  % === Match Timer fallback ===
  'WAIT_FOR_BLOCK',       'MATCH_COMPLETE','[match_time >= 180]',                           6, 0
  'DRIVE_TO_TOWER_AREA',  'MATCH_COMPLETE','[match_time >= 180]',                           6, 0
  'NAV_TO_L2',          'MATCH_COMPLETE','[match_time >= 180]',                           6, 0
  'RETURN_TO_TRANSFER', 'MATCH_COMPLETE','[match_time >= 180]',                           6, 0

  % === Error Recovery ===
  'CLIMBING_L1',    'RECOVERY_RETRY', '[sensor_fault == 1]',                              3, 9
  'PICK_BLOCK',     'RECOVERY_RETRY', '[sensor_fault == 1]',                              3, 9
  'ALIGN_TO_SPOT',  'RECOVERY_RETRY', '[sensor_fault == 1]',                              6, 9
  'PLACE_BLOCK',    'RECOVERY_RETRY', '[sensor_fault == 1]',                              3, 9
  'NAV_TO_L2',      'RECOVERY_RETRY', '[sensor_fault == 1]',                              6, 9
  'RECOVERY_RETRY', 'RETURN_TO_TRANSFER','[retry_ok == 1]',                               9, 3
};

for i = 1:size(transDefs,1)
    t = Stateflow.Transition(chart);
    t.Source      = findState(transDefs{i,1});
    t.Destination = findState(transDefs{i,2});
    t.LabelString = transDefs{i,3};
    t.SourceOClock      = transDefs{i,4};
    t.DestinationOClock = transDefs{i,5};
end

%% ======  SIMULINK WIRING: INPUTS  ======
tDefault = [0; 180];
for i = 1:size(inputDefs,1)
    sig = inputDefs{i,1};
    yPos = 30 + (i-1)*32;
    add_block('simulink/Sources/From Workspace', [modelName '/' sig], ...
        'Position', [30, yPos, 160, yPos+22], ...
        'VariableName', [sig '_ts'], ...
        'SampleTime', '0.1', ...
        'OutputAfterFinalValue', 'Holding final value');
    add_line(modelName, [sig '/1'], ['BR_Autonomous_Brain/' num2str(i)], 'autorouting', 'smart');
    if strcmp(sig, 'block_color'), defVal = [1;1]; else, defVal = [0;0]; end
    ts = timeseries(defVal, tDefault); ts.Name = sig;
    assignin('base', [sig '_ts'], ts);
end

%% ======  SIMULINK WIRING: OUTPUTS  ======
add_block('simulink/Sinks/Display', [modelName '/State_Display'], ...
    'Position', [860, 40, 960, 75]);
add_line(modelName, 'BR_Autonomous_Brain/1', 'State_Display/1', 'autorouting', 'smart');

for j = 1:size(outputDefs,1)
    nm = outputDefs{j,1};
    yPos = 110 + (j-1)*50;
    add_block('simulink/Sinks/Out1', [modelName '/' nm], ...
        'Position', [860, yPos, 900, yPos+20], 'Port', num2str(j));
    add_line(modelName, ['BR_Autonomous_Brain/' num2str(j)], [nm '/1'], 'autorouting', 'smart');
end

%% ======  SAVE & OPEN  ======
save_system(modelName);
open_system(modelName);
open_system(chartPath);

fprintf('\n==============================================================\n');
fprintf('  BR FSM v3 (FULL REFACTOR) generated!\n');
fprintf('  States:      %d (incl. stair climbing sub-states)\n', numStates);
fprintf('  Transitions: %d\n', size(transDefs,1));
fprintf('  Inputs:      %d | Outputs: %d\n', size(inputDefs,1), size(outputDefs,1));
fprintf('  Gripper:     Mechanical Clamp (limit switch feedback)\n');
fprintf('  Navigation:  LiDAR + IMU + Encoder dead reckoning\n');
fprintf('  Sensing:     Depth Camera (block/spot/mustika detection)\n');
fprintf('==============================================================\n\n');
fprintf('  Next: run test_br_scenario to simulate the full match.\n\n');
