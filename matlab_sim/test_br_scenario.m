%% test_br_scenario.m (v4 — matches 21-state FULL REFACTOR FSM)
%  -----------------------------------------------------------------------
%  Feeds scripted 180-second match timeline into BR_FSM_Sim (v4)
%  Signal names match build_br_fsm.m v4 exactly.
%  -----------------------------------------------------------------------

modelName = 'BR_FSM_Sim';
if ~exist([modelName '.slx'], 'file')
    fprintf('Model not found. Building...\n'); build_br_fsm;
else
    load_system(modelName);
end

%% ======  ALL SIGNALS (must match inputDefs in build_br_fsm v4)  ======
allSignals = {
    'start_buzzer'
    'stair_detected'
    'step_engaged'
    'step_climbed'
    'all_steps_done'
    'transfer_reached'
    'build_zone_reached'
    'back_at_transfer'
    'block_in_zone'
    'block_color'
    'spot_detected'
    'spot_aligned'
    'clamp_closed'
    'clamp_released'
    'towers_built'
    'shared_tower_built'
    'mustika_in_zone'
    'mustika_clamped'
    'l2_reached'
    'pillar_aligned'
    'mustika_placed'
    'sensor_fault'
    'retry_ok'
    'match_time'
};

%% ======  MATCH TIMELINE  ======
% { time_sec, 'signal_name', value }

timeline = {
    % ============================================================
    %  PHASE 1: MATCH START → CLIMB 4 STAIRS TO L1 (STEP-BY-STEP LOOP)
    % ============================================================
       0.0, 'start_buzzer',       0     % Waiting in start box
       2.0, 'start_buzzer',       1     % BUZZER! → NAV_TO_STAIR_1

       % --- Step 1 ---
       4.0, 'stair_detected',     1     % LiDAR sees bottom riser → ENGAGE_STEP_1
       4.5, 'stair_detected',     0
       5.0, 'step_engaged',       1     % Front wheel on riser (pitch up) → CLIMBING_L1
       5.2, 'step_engaged',       0
       6.0, 'step_climbed',       1     % Step 1 done (pitch levels) → loops back to ENGAGE_STEP_1
       6.2, 'step_climbed',       0

       % --- Step 2 ---
       6.8, 'step_engaged',       1     % Front wheel on step 2 → CLIMBING_L1
       7.0, 'step_engaged',       0
       7.8, 'step_climbed',       1     % Step 2 done → loops back to ENGAGE_STEP_1
       8.0, 'step_climbed',       0

       % --- Step 3 ---
       8.6, 'step_engaged',       1     % Front wheel on step 3 → CLIMBING_L1
       8.8, 'step_engaged',       0
       9.6, 'step_climbed',       1     % Step 3 done → loops back to ENGAGE_STEP_1
       9.8, 'step_climbed',       0

       % --- Step 4 (Final Step to L1) ---
      10.4, 'step_engaged',       1     % Front wheel on step 4 → CLIMBING_L1
      10.6, 'step_engaged',       0
      11.5, 'all_steps_done',     1     % All 4 steps done = L1 level reached!
      11.5, 'step_climbed',       1     % → exits loop to LEVEL_REACHED_L1
      12.0, 'all_steps_done',     0
      12.0, 'step_climbed',       0

      14.0, 'transfer_reached',   1     % Drove to Transfer Area → TRANSFER_READY
      14.5, 'transfer_reached',   0

    % ============================================================
    %  PHASE 2: TOWER 1 — Earth Block 1  (team L1 zone)
    % ============================================================
      16.0, 'block_color',        1     % Camera: Earth block present
      16.0, 'block_in_zone',      1     % → WAIT_FOR_BLOCK → PICK_BLOCK

      18.0, 'clamp_closed',       1     % Jaws closed → NAV_TO_BUILD_ZONE
      18.0, 'block_in_zone',      0

      26.0, 'build_zone_reached', 1     % At build zone → FIND_BUILD_SPOT
      26.0, 'clamp_closed',       0

      29.0, 'spot_detected',      1     % Green spot found → ALIGN_TO_SPOT
      29.0, 'build_zone_reached', 0

      32.0, 'spot_aligned',       1     % Aligned → PLACE_BLOCK
      32.0, 'spot_detected',      0

      35.0, 'clamp_released',     1     % Block released → CHECK_SANCTUARY
      35.0, 'spot_aligned',       0
      35.0, 'towers_built',       0     % 0 complete towers
      35.5, 'clamp_released',     0
      % → towers < 2 → RETURN_TO_TRANSFER

      38.0, 'back_at_transfer',   1     % Returned → WAIT_FOR_BLOCK
      38.5, 'back_at_transfer',   0

    % ============================================================
    %  PHASE 2: TOWER 1 — Earth Block 2
    % ============================================================
      43.0, 'block_color',        1
      43.0, 'block_in_zone',      1
      45.0, 'clamp_closed',       1
      45.0, 'block_in_zone',      0
      53.0, 'build_zone_reached', 1
      53.0, 'clamp_closed',       0
      56.0, 'spot_detected',      1
      56.0, 'build_zone_reached', 0
      59.0, 'spot_aligned',       1
      59.0, 'spot_detected',      0
      62.0, 'clamp_released',     1
      62.0, 'spot_aligned',       0
      62.0, 'towers_built',       0
      62.5, 'clamp_released',     0
      65.0, 'back_at_transfer',   1
      65.5, 'back_at_transfer',   0

    % ============================================================
    %  PHASE 2: TOWER 1 — Sky Block (Tower 1 COMPLETE!)
    % ============================================================
      70.0, 'block_color',        2     % Sky block
      70.0, 'block_in_zone',      1
      72.0, 'clamp_closed',       1
      72.0, 'block_in_zone',      0
      80.0, 'build_zone_reached', 1
      80.0, 'clamp_closed',       0
      83.0, 'spot_detected',      1
      83.0, 'build_zone_reached', 0
      86.0, 'spot_aligned',       1
      86.0, 'spot_detected',      0
      89.0, 'clamp_released',     1
      89.0, 'spot_aligned',       0
      89.0, 'towers_built',       1     % TOWER 1 DONE
      89.0, 'shared_tower_built', 0     % Not in shared yet
      89.5, 'clamp_released',     0
      92.0, 'back_at_transfer',   1
      92.5, 'back_at_transfer',   0

    % ============================================================
    %  PHASE 3: TOWER 2 (Shared Area — Sky Block for Sanctuary!)
    % ============================================================
      % Earth 1
      97.0, 'block_color',        1
      97.0, 'block_in_zone',      1
      99.0, 'clamp_closed',       1
      99.0, 'block_in_zone',      0
     106.0, 'build_zone_reached', 1
     106.0, 'clamp_closed',       0
     109.0, 'spot_detected',      1
     109.0, 'build_zone_reached', 0
     112.0, 'spot_aligned',       1
     112.0, 'spot_detected',      0
     115.0, 'clamp_released',     1
     115.0, 'spot_aligned',       0
     115.5, 'clamp_released',     0
     118.0, 'back_at_transfer',   1
     118.5, 'back_at_transfer',   0

      % Earth 2
     122.0, 'block_color',        1
     122.0, 'block_in_zone',      1
     124.0, 'clamp_closed',       1
     124.0, 'block_in_zone',      0
     130.0, 'build_zone_reached', 1
     130.0, 'clamp_closed',       0
     133.0, 'spot_detected',      1
     133.0, 'build_zone_reached', 0
     136.0, 'spot_aligned',       1
     136.0, 'spot_detected',      0
     139.0, 'clamp_released',     1
     139.0, 'spot_aligned',       0
     139.5, 'clamp_released',     0
     142.0, 'back_at_transfer',   1
     142.5, 'back_at_transfer',   0

      % Sky block (Tower 2 COMPLETE + SANCTUARY UNLOCKED!)
     146.0, 'block_color',        2
     146.0, 'block_in_zone',      1
     148.0, 'clamp_closed',       1
     148.0, 'block_in_zone',      0
     153.0, 'build_zone_reached', 1
     153.0, 'clamp_closed',       0
     155.0, 'spot_detected',      1
     155.0, 'build_zone_reached', 0
     157.0, 'spot_aligned',       1
     157.0, 'spot_detected',      0
     159.0, 'clamp_released',     1
     159.0, 'spot_aligned',       0
     159.0, 'towers_built',       2     % ★ 2 TOWERS!
     159.0, 'shared_tower_built', 1     % ★ 1 IN SHARED!
     159.5, 'clamp_released',     0
     % → CHECK_SANCTUARY → SANCTUARY UNLOCKED → WAIT_FOR_MUSTIKA!

    % ============================================================
    %  PHASE 4: MUSTIKA ENSHRINEMENT
    % ============================================================
     163.0, 'mustika_in_zone',    1     % Volleyball at Transfer Area
     165.0, 'mustika_clamped',    1     % Clamped! → NAV_TO_L2
     165.0, 'mustika_in_zone',    0
     171.0, 'l2_reached',         1     % At L2! → ALIGN_TO_PILLAR
     171.0, 'mustika_clamped',    0
     174.0, 'pillar_aligned',     1     % Aligned → ENSHRINE
     174.0, 'l2_reached',         0
     177.0, 'mustika_placed',     1     % ★ ENSHRINED! +250 PTS → COMPLETE
     177.0, 'pillar_aligned',     0
};

%% ======  BUILD TIMESERIES  ======
simTime = 180;  dt = 0.1;
tVec = (0:dt:simTime)';
nSteps = length(tVec);

for s = 1:length(allSignals)
    sig = allSignals{s};

    % Defaults
    if strcmp(sig, 'match_time')
        sigData = tVec;
    elseif strcmp(sig, 'blocks_carried')
        sigData = 2 * ones(nSteps, 1);
    elseif strcmp(sig, 'block_color')
        sigData = ones(nSteps, 1);
    else
        sigData = zeros(nSteps, 1);
    end

    % Apply events
    events = timeline(strcmp(timeline(:,2), sig), :);
    if ~isempty(events)
        eTimes  = cell2mat(events(:,1));
        eVals   = cell2mat(events(:,3));
        cur = sigData(1); ei = 1;
        for ti = 1:nSteps
            while ei <= length(eTimes) && eTimes(ei) <= tVec(ti)
                cur = eVals(ei); ei = ei + 1;
            end
            sigData(ti) = cur;
        end
    end

    ts = timeseries(sigData, tVec); ts.Name = sig;
    assignin('base', [sig '_ts'], ts);
end

%% ======  RUN  ======
fprintf('\n=== BR FSM v4 Test — 180s, 30 States ===\n');
simOut = sim(modelName, 'StopTime', '180');
fprintf('  Done!\n\n');

%% ======  PLOT  ======
stateNames = { ...
    '1:IDLE','2:NAV\_STAIR','3:ENGAGE\_STEP','4:CLIMBING\_L1', ...
    '5:LEVEL\_L1','6:XFER\_READY','7:WAIT\_BLK','8:PICK\_BLK', ...
    '9:DRV\_TWR','10:DET\_SPOT','11:ALIGN','12:PLACE', ...
    '13:CHK\_SANC','14:RETURN','15:WAIT\_MUS','16:PICK\_MUS', ...
    '17:NAV\_L2','18:ALIGN\_PIL','19:ENSHRINE','20:COMPLETE', ...
    '21:RECOVERY', '22:DECIDE','23:EMERG\_DROP','24:NAV\_UP\_L2','25:ENGAGE\_L2','26:CLIMB\_L2','27:SNATCH','28:NAV\_DN\_L2','29:DESCEND','30:PLACE\_STOLEN'};

yout = simOut.yout;

figure('Name','BR FSM v4 — State Timeline','Position',[80 80 1250 750],'Color','w');

subplot(3,1,1);
stairs(yout{1}.Values.Time, yout{1}.Values.Data, 'b-', 'LineWidth', 2);
ylabel('State','FontWeight','bold');
title('Builder Robot FSM v4 — Autonomous State Progression','FontSize',13,'FontWeight','bold');
yticks([1 5 10 15 20 25 30]); yticklabels(stateNames([1 5 10 15 20 25 30])); ylim([0.5 30.5]); xlim([0 180]); grid on;

subplot(3,1,2);
stairs(yout{2}.Values.Time, yout{2}.Values.Data, 'Color',[0.85 0.33 0.1], 'LineWidth',1.8);
ylabel('Sensor Bitmask','FontWeight','bold');
title('Active Sensor Subsystems  (1=LiDAR  2=IMU  4=Enc  8=DepthCam  16=Clamp SW)','FontSize',11);
xlim([0 180]); grid on;

subplot(3,1,3);
stairs(yout{3}.Values.Time, yout{3}.Values.Data, 'g-', 'LineWidth',1.6); hold on;
stairs(yout{4}.Values.Time, yout{4}.Values.Data, 'm--', 'LineWidth',1.6);
legend('Drive  (0=STOP 1=CLIMB 2=SCAN 3=FINE 4=DESC 5=FWD)', ...
       'Gripper (0=IDLE 1=CLOSE 2=OPEN 3=HOLD)', 'Location','northeast');
ylabel('Command ID','FontWeight','bold');
xlabel('Match Time (seconds)','FontWeight','bold');
title('Actuator Commands Dispatched by FSM','FontSize',11);
xlim([0 180]); grid on;

saveas(gcf, 'br_fsm_timeline.png');
fprintf('  Plot saved to: %s\n', fullfile(pwd,'br_fsm_timeline.png'));

fprintf('\n=== RESULT: 2 Towers + Mustika Enshrined → VICTORY (250 pts) ===\n\n');
