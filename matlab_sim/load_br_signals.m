% load_br_signals.m
% Auto-generates the timeseries inputs required for the BR FSM V4

tDefault = [0; 180];
signals = {
    'start_buzzer', 0; 'stair_detected', 0; 'step_engaged', 0; 'step_climbed', 0;
    'all_steps_done', 0; 'transfer_reached', 0; 'build_zone_reached', 0; 'back_at_transfer', 0;
    'block_in_zone', 0; 'block_color', 1; 'spot_detected', 0; 'spot_aligned', 0;
    'clamp_closed', 0; 'clamp_released', 0; 'towers_built', 0; 'shared_tower_built', 0;
    'mustika_in_zone', 0; 'mustika_clamped', 0; 'l2_reached', 0; 'pillar_aligned', 0;
    'mustika_placed', 0; 'sensor_fault', 0; 'retry_ok', 0; 'match_time', 0;
    'tr_in_transfer_area', 0; 'opponent_in_shared', 0; 'enemy_sky_vulnerable', 0; 'blocks_carried', 2;
};

for i = 1:size(signals,1)
    sig = signals{i,1};
    val = signals{i,2};
    ts = timeseries([val; val], tDefault);
    ts.Name = sig;
    assignin('base', [sig '_ts'], ts);
end
disp('V4 BR FSM signals loaded into workspace successfully.');
