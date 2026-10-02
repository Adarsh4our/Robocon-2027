%% build_br_fsm.m  (v4 — STRATEGIC EXPANSION)
%  -----------------------------------------------------------------------
%  ABU Robocon 2027 — Builder Robot (BR) Finite State Machine
%  Adds Tactical Evaluator, 2-Block Carrying, Snatcher, and Emergency Drop
%  Maintains original 21-state grid layout and adds to Row 6-8 and Col 6.
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
    'block_color',         'Depth Cam: 1=Earth(Red/Blue) 2=Sky'
    'spot_detected',       'Depth Cam: green 500x500mm build spot found (0/1)'
    'spot_aligned',        'Depth Cam: alignment error < 5mm (0/1)'
    % Gripper
    'clamp_closed',        'Limit switch: both jaws fully closed on block (0/1)'
    'clamp_released',      'Limit switch: jaws fully open, block free (0/1)'
    % Tower tracking
    'towers_built',        'Counter: total complete towers (Earth+Earth+Sky)'
    'shared_tower_built',  'Flag: 1 if tower placed in shared area (0/1)'
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
    % --- NEW STRATEGIC INPUTS ---
    'tr_in_transfer_area', 'TR is currently violating Transfer Airspace (0/1)'
    'opponent_in_shared',  'Opponent detected blocking Shared L1 Zone (0/1)'
    'enemy_sky_vulnerable','Opponent Sky block on L2 without Mustika (0/1)'
    'blocks_carried',      'Payload counter (0, 1, or 2)'
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
    'current_state',  'State ID 1-30'
    'active_sensors', 'Sensor bitmask'
    'drive_cmd',      '0=STOP 1=CLIMB_STAIR 2=SCAN 3=FINE_POS 4=DESCEND 5=DRIVE_FWD'
    'gripper_cmd',    '0=IDLE 1=CLAMP_EARTH 2=OPEN_CLAMP 3=HOLD 5=CLAMP_SKY 6=CLAMP_MUSTIKA'
    'arm_cmd',        '0=STOW 1=EXTEND 2=LOWER 3=LIFT 4=HOVER'
    'status_msg',     '-1=FAULT 0=STANDBY 1-20=PROGRESS 99=VICTORY'
    'target_steps',   'Steps needed for current climb (5 for L1, 3 for L2)'
};

for i = 1:size(outputDefs,1)
    d = Stateflow.Data(chart);
    d.Name = outputDefs{i,1}; d.Scope = 'Output';
    d.Props.Type.Method = 'Built-in';
    d.Props.Type.Primitive = 'double';
    d.Description = outputDefs{i,2};
end

%% ======  STATE DEFINITIONS  ======
% Original Rows 1-5 + Side Col 5. New Rows 6-8 + Side Col 6.

stateDefs = {
  % === ROW 1 ===
  'IDLE', 1, {'current_state=1;','active_sensors=0;','drive_cmd=0;','gripper_cmd=0;','arm_cmd=0;','status_msg=0;','target_steps=0;'}, 1,1
  'NAV_TO_STAIR_1', 2, {'current_state=2;','active_sensors=7;','drive_cmd=5;','gripper_cmd=0;','arm_cmd=0;','status_msg=1;'}, 2,1
  'ENGAGE_STEP_1', 3, {'current_state=3;','active_sensors=7;','drive_cmd=1;','gripper_cmd=0;','arm_cmd=0;','status_msg=2;'}, 3,1
  'CLIMBING_L1', 4, {'current_state=4;','active_sensors=7;','drive_cmd=1;','gripper_cmd=0;','arm_cmd=0;','status_msg=3;','target_steps=5;'}, 4,1

  % === ROW 2 ===
  'LEVEL_REACHED_L1', 5, {'current_state=5;','active_sensors=3;','drive_cmd=0;','gripper_cmd=0;','arm_cmd=0;','status_msg=4;'}, 4,2
  'TRANSFER_READY', 6, {'current_state=6;','active_sensors=9;','drive_cmd=5;','gripper_cmd=0;','arm_cmd=0;','status_msg=5;'}, 3,2
  'WAIT_FOR_BLOCK', 7, {'current_state=7;','active_sensors=9;','drive_cmd=0;','gripper_cmd=0;','arm_cmd=0;','status_msg=6;'}, 2,2
  'PICK_BLOCK', 8, {'current_state=8;','active_sensors=20;','drive_cmd=0;','gripper_cmd=1;','arm_cmd=3;','status_msg=7;'}, 1,2

  % === ROW 3 ===
  'DRIVE_TO_TOWER_AREA', 9, {'current_state=9;','active_sensors=7;','drive_cmd=5;','gripper_cmd=3;','arm_cmd=4;','status_msg=8;'}, 1,3
  'DETECT_GREEN_SPOT', 10, {'current_state=10;','active_sensors=9;','drive_cmd=2;','gripper_cmd=3;','arm_cmd=4;','status_msg=9;'}, 2,3
  'ALIGN_TO_SPOT', 11, {'current_state=11;','active_sensors=9;','drive_cmd=3;','gripper_cmd=3;','arm_cmd=4;','status_msg=10;'}, 3,3
  'PLACE_BLOCK', 12, {'current_state=12;','active_sensors=24;','drive_cmd=0;','gripper_cmd=2;','arm_cmd=2;','status_msg=11;'}, 4,3

  % === ROW 4 ===
  'CHECK_SANCTUARY', 13, {'current_state=13;','active_sensors=0;','drive_cmd=0;','gripper_cmd=0;','arm_cmd=0;','status_msg=12;'}, 4,4
  'RETURN_TO_TRANSFER', 14, {'current_state=14;','active_sensors=7;','drive_cmd=4;','gripper_cmd=0;','arm_cmd=0;','status_msg=13;'}, 3,4
  'WAIT_FOR_MUSTIKA', 15, {'current_state=15;','active_sensors=9;','drive_cmd=0;','gripper_cmd=0;','arm_cmd=0;','status_msg=14;'}, 2,4
  'PICK_MUSTIKA', 16, {'current_state=16;','active_sensors=24;','drive_cmd=0;','gripper_cmd=6;','arm_cmd=3;','status_msg=15;'}, 1,4

  % === ROW 5 ===
  'NAV_TO_L2', 17, {'current_state=17;','active_sensors=7;','drive_cmd=1;','gripper_cmd=3;','arm_cmd=0;','status_msg=16;'}, 1,5
  'ALIGN_TO_PILLAR', 18, {'current_state=18;','active_sensors=9;','drive_cmd=3;','gripper_cmd=3;','arm_cmd=4;','status_msg=17;'}, 2,5
  'ENSHRINE_MUSTIKA', 19, {'current_state=19;','active_sensors=24;','drive_cmd=0;','gripper_cmd=2;','arm_cmd=2;','status_msg=18;'}, 3,5
  'MATCH_COMPLETE', 20, {'current_state=20;','active_sensors=0;','drive_cmd=0;','gripper_cmd=0;','arm_cmd=0;','status_msg=99;'}, 4,5
  
  % === ROW 3 SIDE ===
  'RECOVERY_RETRY', 21, {'current_state=21;','active_sensors=7;','drive_cmd=4;','gripper_cmd=2;','arm_cmd=0;','status_msg=-1;'}, 5,3

  % === NEW: ROW 6 (Basement Tactics) ===
  'DECIDE_TACTICAL', 22, {'current_state=22;','active_sensors=9;','drive_cmd=0;','gripper_cmd=3;','arm_cmd=4;','status_msg=20;'}, 1,6
  'EMERGENCY_DROP', 23, {'current_state=23;','active_sensors=0;','drive_cmd=0;','gripper_cmd=2;','arm_cmd=0;','status_msg=-99;'}, 6,6

  % === NEW: ROW 7 (Snatch Sequence Up) ===
  'NAV_STAIR_UP_L2', 24, {'current_state=24;','active_sensors=7;','drive_cmd=5;','gripper_cmd=3;','arm_cmd=0;','status_msg=21;'}, 1,7
  'ENGAGE_L2', 25, {'current_state=25;','active_sensors=7;','drive_cmd=1;','gripper_cmd=3;','arm_cmd=0;','status_msg=22;'}, 2,7
  'CLIMBING_L2', 26, {'current_state=26;','active_sensors=7;','drive_cmd=1;','gripper_cmd=3;','arm_cmd=0;','status_msg=23;','target_steps=3;'}, 3,7
  'SNATCH_BLOCK', 27, {'current_state=27;','active_sensors=24;','drive_cmd=0;','gripper_cmd=5;','arm_cmd=3;','status_msg=24;'}, 4,7

  % === NEW: ROW 8 (Snatch Sequence Down) ===
  'NAV_STAIR_DOWN_L2', 28, {'current_state=28;','active_sensors=7;','drive_cmd=4;','gripper_cmd=3;','arm_cmd=0;','status_msg=25;'}, 4,8
  'DESCENDING_L2', 29, {'current_state=29;','active_sensors=7;','drive_cmd=4;','gripper_cmd=3;','arm_cmd=0;','status_msg=26;','target_steps=3;'}, 3,8
  'PLACE_STOLEN', 30, {'current_state=30;','active_sensors=24;','drive_cmd=0;','gripper_cmd=2;','arm_cmd=2;','status_msg=27;'}, 2,8
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
transDefs = {
  % === ROW 1 ===
  'IDLE',           'NAV_TO_STAIR_1', '[start_buzzer == 1]',                              3, 9
  'NAV_TO_STAIR_1', 'ENGAGE_STEP_1',  '[stair_detected == 1]',                            3, 9
  'ENGAGE_STEP_1',  'CLIMBING_L1',    '[step_engaged == 1]',                              3, 9
  'CLIMBING_L1',    'ENGAGE_STEP_1',  '[step_climbed == 1 && all_steps_done == 0]',       0, 0
  'CLIMBING_L1',    'LEVEL_REACHED_L1','[all_steps_done == 1]',                           6, 0

  % === ROW 2 ===
  'LEVEL_REACHED_L1','TRANSFER_READY','[transfer_reached == 1]',                          9, 3
  'TRANSFER_READY', 'WAIT_FOR_BLOCK', '[block_color > 0]',                                9, 3
  
  % Mod: Wait for TR airspace clearance
  'WAIT_FOR_BLOCK', 'PICK_BLOCK',     '[block_in_zone == 1 && tr_in_transfer_area == 0]', 9, 3

  % === THE MULTI-BLOCK CARRY LOOP ===
  'PICK_BLOCK',     'WAIT_FOR_BLOCK', '[clamp_closed == 1 && blocks_carried < 2 && block_color == 1]',        0, 6

  % === ROW 3: Pick → Tactical Evaluator (was Drive to Tower) ===
  'PICK_BLOCK',     'DECIDE_TACTICAL', '[clamp_closed == 1 && (blocks_carried == 2 || block_color == 2)]',      6, 0
  
  % Tactical Routing
  'DECIDE_TACTICAL', 'DRIVE_TO_TOWER_AREA', '[enemy_sky_vulnerable == 0 && opponent_in_shared == 0]', 0, 6
  'DECIDE_TACTICAL', 'NAV_STAIR_UP_L2',     '[enemy_sky_vulnerable == 1]', 6, 0
  
  'DRIVE_TO_TOWER_AREA',  'DETECT_GREEN_SPOT',  '[build_zone_reached == 1]',              3, 9
  'DETECT_GREEN_SPOT',    'ALIGN_TO_SPOT',      '[spot_detected == 1]',                   3, 9
  'ALIGN_TO_SPOT',        'PLACE_BLOCK',        '[spot_aligned == 1]',                    3, 9
  'PLACE_BLOCK',          'CHECK_SANCTUARY',    '[clamp_released == 1]',                  6, 0

  % === ROW 4 ===
  'CHECK_SANCTUARY','RETURN_TO_TRANSFER','[towers_built < 2 || shared_tower_built == 0]', 9, 3
  'RETURN_TO_TRANSFER','WAIT_FOR_BLOCK','[back_at_transfer == 1]',                        0, 6
  'CHECK_SANCTUARY','WAIT_FOR_MUSTIKA','[towers_built >= 2 && shared_tower_built == 1]',  9, 9

  % === ROW 5 ===
  'WAIT_FOR_MUSTIKA','PICK_MUSTIKA',  '[mustika_in_zone == 1]',                           9, 3
  'PICK_MUSTIKA',   'NAV_TO_L2',     '[mustika_clamped == 1]',                            6, 0
  'NAV_TO_L2',      'ALIGN_TO_PILLAR','[l2_reached == 1]',                               3, 9
  'ALIGN_TO_PILLAR','ENSHRINE_MUSTIKA','[pillar_aligned == 1]',                           3, 9
  'ENSHRINE_MUSTIKA','NAV_STAIR_DOWN_L2','[mustika_placed == 1]',                         6, 0

  % === ROW 7 & 8: Snatcher Sequence ===
  'NAV_STAIR_UP_L2', 'ENGAGE_L2',     '[stair_detected == 1]',                            3, 9
  'ENGAGE_L2',       'CLIMBING_L2',   '[step_engaged == 1]',                              3, 9
  'CLIMBING_L2',     'ENGAGE_L2',     '[step_climbed == 1 && all_steps_done == 0]',       0, 0
  'CLIMBING_L2',     'SNATCH_BLOCK',  '[all_steps_done == 1]',                            3, 9
  'SNATCH_BLOCK',    'NAV_STAIR_DOWN_L2', '[clamp_closed == 1]',                          6, 0
  'NAV_STAIR_DOWN_L2','DESCENDING_L2','[stair_detected == 1]',                            9, 3
  'DESCENDING_L2',   'PLACE_STOLEN',  '[all_steps_done == 1 && clamp_closed == 1]',       9, 3
  'DESCENDING_L2',   'RETURN_TO_TRANSFER','[all_steps_done == 1 && clamp_closed == 0]',   0, 6
  'PLACE_STOLEN',    'DECIDE_TACTICAL','[clamp_released == 1]',                           9, 3

  % === 178.5s EMERGENCY DROP TRAPS ===
  'DRIVE_TO_TOWER_AREA', 'EMERGENCY_DROP', '[match_time >= 178.5]', 3, 9
  'NAV_TO_L2',           'EMERGENCY_DROP', '[match_time >= 178.5]', 3, 9
  'NAV_STAIR_DOWN_L2',   'EMERGENCY_DROP', '[match_time >= 178.5]', 3, 9
  'EMERGENCY_DROP',      'MATCH_COMPLETE', '[clamp_released == 1]', 0, 3

  % === Normal Timeouts ===
  'WAIT_FOR_BLOCK',       'MATCH_COMPLETE','[match_time >= 180]',                           6, 0
  'RETURN_TO_TRANSFER',   'MATCH_COMPLETE','[match_time >= 180]',                           6, 0

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
    if strcmp(sig, 'block_color')
        defVal = [1;1];
    elseif strcmp(sig, 'blocks_carried')
        defVal = [2;2]; % Default 2 to prevent infinite loop for testing
    else
        defVal = [0;0];
    end
    ts = timeseries(defVal, tDefault); ts.Name = sig;
    assignin('base', [sig '_ts'], ts);
end

%% ======  SIMULINK WIRING: OUTPUTS  ======
add_block('simulink/Sinks/Display', [modelName '/State_Display'], ...
    'Position', [1060, 40, 1160, 75]);
add_line(modelName, 'BR_Autonomous_Brain/1', 'State_Display/1', 'autorouting', 'smart');

for j = 1:size(outputDefs,1)
    nm = outputDefs{j,1};
    yPos = 110 + (j-1)*50;
    add_block('simulink/Sinks/Out1', [modelName '/' nm], ...
        'Position', [1060, yPos, 1100, yPos+20], 'Port', num2str(j));
    add_line(modelName, ['BR_Autonomous_Brain/' num2str(j)], [nm '/1'], 'autorouting', 'smart');
end

%% ======  SAVE & OPEN  ======
save_system(modelName);
open_system(modelName);
open_system(chartPath);

fprintf('\n==============================================================\n');
fprintf('  BR FSM v4 (STRATEGIC EXPANSION) generated!\n');
fprintf('  States:      %d (added Snatch, Eval, Emergency Drop)\n', numStates);
fprintf('  Transitions: %d\n', size(transDefs,1));
fprintf('  Inputs:      %d | Outputs: %d\n', size(inputDefs,1), size(outputDefs,1));
fprintf('==============================================================\n');
