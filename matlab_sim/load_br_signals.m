%% load_br_signals.m
%  -----------------------------------------------------------------------
%  Populates the 24 input timeseries variables (*_ts) into the base workspace.
%  Automatically called by Simulink's InitFcn callback when clicking 'Run'.
%  -----------------------------------------------------------------------

simTime = 180;
dt = 0.1;
tVec = (0:dt:simTime)';
nSteps = length(tVec);

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
timeline = {
    % --- Phase 1: Climb 4 Stairs to L1 ---
       0.0, 'start_buzzer',       0
       2.0, 'start_buzzer',       1

       % Step 1
       4.0, 'stair_detected',     1
       4.5, 'stair_detected',     0
       5.0, 'step_engaged',       1
       5.2, 'step_engaged',       0
       6.0, 'step_climbed',       1
       6.2, 'step_climbed',       0

       % Step 2
       6.8, 'step_engaged',       1
       7.0, 'step_engaged',       0
       7.8, 'step_climbed',       1
       8.0, 'step_climbed',       0

       % Step 3
       8.6, 'step_engaged',       1
       8.8, 'step_engaged',       0
       9.6, 'step_climbed',       1
       9.8, 'step_climbed',       0

       % Step 4 (L1 Reached)
      10.4, 'step_engaged',       1
      10.6, 'step_engaged',       0
      11.5, 'all_steps_done',     1
      11.5, 'step_climbed',       1
      12.0, 'all_steps_done',     0
      12.0, 'step_climbed',       0

      14.0, 'transfer_reached',   1
      14.5, 'transfer_reached',   0

    % --- Tower 1: Earth 1 ---
      16.0, 'block_color',        1
      16.0, 'block_in_zone',      1
      18.0, 'clamp_closed',       1
      18.0, 'block_in_zone',      0
      26.0, 'build_zone_reached', 1
      26.0, 'clamp_closed',       0
      29.0, 'spot_detected',      1
      29.0, 'build_zone_reached', 0
      32.0, 'spot_aligned',       1
      32.0, 'spot_detected',      0
      35.0, 'clamp_released',     1
      35.0, 'spot_aligned',       0
      35.0, 'towers_built',       0
      35.5, 'clamp_released',     0
      38.0, 'back_at_transfer',   1
      38.5, 'back_at_transfer',   0

    % --- Tower 1: Earth 2 ---
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

    % --- Tower 1: Sky 1 (Complete) ---
      70.0, 'block_color',        2
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
      89.0, 'towers_built',       1
      89.0, 'shared_tower_built', 0
      89.5, 'clamp_released',     0
      92.0, 'back_at_transfer',   1
      92.5, 'back_at_transfer',   0

    % --- Tower 2 (Shared Area): Earth 1 ---
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

    % --- Tower 2: Earth 2 ---
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

    % --- Tower 2: Sky Block (Complete + Sanctuary Unlocked!) ---
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
     159.0, 'towers_built',       2
     159.0, 'shared_tower_built', 1
     159.5, 'clamp_released',     0

    % --- Mustika Enshrinement ---
     163.0, 'mustika_in_zone',    1
     165.0, 'mustika_clamped',    1
     165.0, 'mustika_in_zone',    0
     171.0, 'l2_reached',         1
     171.0, 'mustika_clamped',    0
     174.0, 'pillar_aligned',     1
     174.0, 'l2_reached',         0
     177.0, 'mustika_placed',     1
     177.0, 'pillar_aligned',     0
};

%% ======  CONVERT TIMELINE TO TIMESERIES IN BASE WORKSPACE  ======
for s = 1:length(allSignals)
    sig = allSignals{s};
    if strcmp(sig, 'match_time')
        sigData = tVec;
    elseif strcmp(sig, 'block_color')
        sigData = ones(nSteps, 1);
    else
        sigData = zeros(nSteps, 1);
    end

    events = timeline(strcmp(timeline(:,2), sig), :);
    if ~isempty(events)
        eTimes = cell2mat(events(:,1));
        eVals  = cell2mat(events(:,3));
        cur = sigData(1); ei = 1;
        for ti = 1:nSteps
            while ei <= length(eTimes) && eTimes(ei) <= tVec(ti)
                cur = eVals(ei); ei = ei + 1;
            end
            sigData(ti) = cur;
        end
    end

    ts = timeseries(sigData, tVec);
    ts.Name = sig;
    assignin('base', [sig '_ts'], ts);
end
