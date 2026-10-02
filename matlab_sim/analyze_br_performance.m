%% analyze_br_performance.m
%  -----------------------------------------------------------------------
%  ABU Robocon 2027 — Builder Robot (BR)
%  Speed Budgeting & Sensor Power Management Analyzer
%
%  NOTE: This script ONLY analyzes simulation output data.
%        It NEVER touches or modifies your Stateflow block positions!
%  -----------------------------------------------------------------------

modelName = 'BR_FSM_Sim';

% Ensure simulation data is available in base workspace
if ~exist('simOut', 'var')
    if ~exist([modelName '.slx'], 'file')
        error('Model %s.slx not found!', modelName);
    end
    fprintf('Running simulation to collect logs...\n');
    test_br_scenario;
end

yout = simOut.yout;
timeVec     = yout{1}.Values.Time;
stateData   = yout{1}.Values.Data;
sensorMask  = yout{2}.Values.Data;
driveCmd    = yout{3}.Values.Data;
gripperCmd  = yout{4}.Values.Data;
dt          = timeVec(2) - timeVec(1);
totalTime   = timeVec(end);

fprintf('\n===============================================================\n');
fprintf('       BUILDER ROBOT — PERFORMANCE & POWER ANALYSIS REPORT     \n');
fprintf('===============================================================\n\n');

%% =======================================================================
%  1. SPEED BUDGETING & TIME ALLOCATION
%  =======================================================================
% Group the 21 states into 5 key competition activities:
% 1) Stair Climbing:  States 2, 3, 4, 5
% 2) Driving/Transit: States 6, 9, 14, 17
% 3) Block Handling:  States 8, 12, 16, 19
% 4) Visual Search:   States 10, 11, 18
% 5) Wait / Idle:     States 1, 7, 13, 15, 20, 21

timeClimb   = sum(ismember(stateData, [2 3 4 5])) * dt;
timeDrive   = sum(ismember(stateData, [6 9 14 17])) * dt;
timeHandle  = sum(ismember(stateData, [8 12 16 19])) * dt;
timeVision  = sum(ismember(stateData, [10 11 18])) * dt;
timeWait    = sum(ismember(stateData, [1 7 13 15 20 21])) * dt;

% Match completion time (first time state reaches 20)
idxComplete = find(stateData == 20, 1);
if ~isempty(idxComplete)
    matchFinishTime = timeVec(idxComplete);
else
    matchFinishTime = totalTime;
end
timeMargin = 180.0 - matchFinishTime;

fprintf('--- PART 1: MATCH STRATEGY & SPEED BUDGET ---\n');
fprintf('  Total Match Time Limit:   180.0 seconds\n');
fprintf('  Match Finished (Victory): %5.1f seconds\n', matchFinishTime);
fprintf('  Safety Time Margin:       %5.1f seconds (under budget!)\n\n', timeMargin);
fprintf('  Time Allocation Breakdown:\n');
fprintf('    • Driving & Navigation:  %5.1f s  (%4.1f%%)\n', timeDrive,  (timeDrive/totalTime)*100);
fprintf('    • Block & Ball Handling: %5.1f s  (%4.1f%%)\n', timeHandle, (timeHandle/totalTime)*100);
fprintf('    • Visual Servoing/Search:%5.1f s  (%4.1f%%)\n', timeVision, (timeVision/totalTime)*100);
fprintf('    • Waiting (TR Delivery): %5.1f s  (%4.1f%%)\n', timeWait,   (timeWait/totalTime)*100);
fprintf('    • Stair Climbing:        %5.1f s  (%4.1f%%)\n', timeClimb,  (timeClimb/totalTime)*100);

%% =======================================================================
%  2. SENSOR DUTY CYCLE & POWER MANAGEMENT
%  =======================================================================
% Hardware Power Specifications (typical competition hardware):
%   - 2D LiDAR (RPLiDAR A2/A3):          3.00 Watts
%   - Depth Camera (Intel RealSense):     3.50 Watts
%   - Wheel Encoders (Optical/Hall):      0.10 Watts
%   - 6-DOF IMU (BNO055 / MPU6050):       0.05 Watts
%   - Clamp Limit Switches:               0.01 Watts

sensorNames = {'2D LiDAR', '6-DOF IMU', 'Wheel Encoders', 'Depth Camera', 'Clamp Limit SW'};
sensorBits  = [1, 2, 4, 8, 16];
sensorWatts = [3.00, 0.05, 0.10, 3.50, 0.01];

activeSeconds = zeros(1, 5);
dutyCycles    = zeros(1, 5);
energyWh_FSM  = zeros(1, 5);
energyWh_AlwaysON = zeros(1, 5);

fprintf('\n--- PART 2: SENSOR DUTY CYCLE & POWER MANAGEMENT ---\n');
fprintf('  %-18s | %-8s | %-10s | %-12s | %-12s\n', ...
    'Sensor Subsystem', 'Power', 'Duty Cycle', 'FSM Energy', 'Always-ON');
fprintf('  -------------------+----------+------------+--------------+--------------\n');

for s = 1:5
    bitVal = sensorBits(s);
    isActive = (bitand(sensorMask, bitVal) > 0);
    activeSeconds(s) = sum(isActive) * dt;
    dutyCycles(s)    = (activeSeconds(s) / totalTime) * 100;
    
    % Energy = Power(W) * Time(hours)
    energyWh_FSM(s)      = sensorWatts(s) * (activeSeconds(s) / 3600);
    energyWh_AlwaysON(s) = sensorWatts(s) * (totalTime / 3600);
    
    fprintf('  %-18s | %4.2f W   | %6.1f %%   | %7.4f Wh   | %7.4f Wh\n', ...
        sensorNames{s}, sensorWatts(s), dutyCycles(s), energyWh_FSM(s), energyWh_AlwaysON(s));
end

totalFSM_Energy      = sum(energyWh_FSM);
totalAlwaysON_Energy = sum(energyWh_AlwaysON);
energySavedPercent   = (1 - (totalFSM_Energy / totalAlwaysON_Energy)) * 100;

fprintf('  -------------------+----------+------------+--------------+--------------\n');
fprintf('  TOTAL SENSOR SUITE | %4.2f W   |     --     | %7.4f Wh   | %7.4f Wh\n', ...
    sum(sensorWatts), totalFSM_Energy, totalAlwaysON_Energy);
fprintf('\n  ★ ENERGY SAVED BY FSM POWER MANAGEMENT: %4.1f%% reduction!\n', energySavedPercent);
fprintf('  ★ Battery Drain Saved: Prevents computer throttling & extends match battery.\n');
fprintf('===============================================================\n\n');

%% =======================================================================
%  3. GENERATE VISUAL DASHBOARD
%  =======================================================================
fig = figure('Name', 'Builder Robot — Strategy & Power Dashboard', ...
    'Position', [100 100 1200 800], 'Color', 'w');

% --- Subplot 1: Speed Budget Donut Chart ---
subplot(2, 2, 1);
activityTimes = [timeDrive, timeHandle, timeVision, timeClimb, timeWait];
activityLabels = {
    sprintf('Drive (%.0fs)', timeDrive), ...
    sprintf('Handling (%.0fs)', timeHandle), ...
    sprintf('Vision (%.0fs)', timeVision), ...
    sprintf('Stairs (%.0fs)', timeClimb), ...
    sprintf('Wait TR (%.0fs)', timeWait)
};
pie(activityTimes, activityLabels);
title('Match Time Budget (180s Total)', 'FontSize', 12, 'FontWeight', 'bold');

% --- Subplot 2: Activity Duration Bar Chart ---
subplot(2, 2, 2);
barCategories = categorical({'Driving', 'Handling', 'Vision Align', 'Stair Climb', 'Waiting'});
barCategories = reordercats(barCategories, {'Driving', 'Handling', 'Vision Align', 'Stair Climb', 'Waiting'});
b = bar(barCategories, activityTimes, 0.6, 'FaceColor', [0.2 0.5 0.8]);
ylabel('Duration (seconds)', 'FontWeight', 'bold');
title(sprintf('Time Spent per Activity (Finish: %.1fs, Margin: %.1fs)', matchFinishTime, timeMargin), ...
    'FontSize', 11, 'FontWeight', 'bold');
grid on;
for k = 1:length(activityTimes)
    text(k, activityTimes(k) + 2, sprintf('%.1fs', activityTimes(k)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 10);
end
ylim([0 max(activityTimes) + 12]);

% --- Subplot 3: Sensor Duty Cycle (%) ---
subplot(2, 2, 3);
sensorCat = categorical(sensorNames);
sensorCat = reordercats(sensorCat, sensorNames);
b2 = bar(sensorCat, dutyCycles, 0.55, 'FaceColor', [0.85 0.33 0.1]);
ylabel('Duty Cycle (% of Match ON)', 'FontWeight', 'bold');
title('Sensor Duty Cycle (Power-Down Management)', 'FontSize', 11, 'FontWeight', 'bold');
grid on;
for k = 1:length(dutyCycles)
    text(k, dutyCycles(k) + 3, sprintf('%.1f%%', dutyCycles(k)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 10);
end
ylim([0 115]);

% --- Subplot 4: Energy Comparison (Wh) ---
subplot(2, 2, 4);
compData = [totalAlwaysON_Energy, totalFSM_Energy];
compCat = categorical({'Always-ON (No FSM)', 'FSM Power Managed'});
compCat = reordercats(compCat, {'Always-ON (No FSM)', 'FSM Power Managed'});
b3 = bar(compCat, compData, 0.5);
b3.FaceColor = 'flat';
b3.CData(1,:) = [0.8 0.2 0.2]; % Red for high waste
b3.CData(2,:) = [0.2 0.7 0.3]; % Green for efficient
ylabel('Total Energy (Watt-hours)', 'FontWeight', 'bold');
title(sprintf('Total Sensor Energy Consumption (-%.1f%% Saved)', energySavedPercent), ...
    'FontSize', 11, 'FontWeight', 'bold');
grid on;
text(1, compData(1) + 0.015, sprintf('%.3f Wh', compData(1)), ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 11);
text(2, compData(2) + 0.015, sprintf('%.3f Wh (Saved!)', compData(2)), ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 11);
ylim([0 max(compData) * 1.3]);

saveas(fig, 'br_performance_dashboard.png');
fprintf('  Plot saved to: %s\n\n', fullfile(pwd, 'br_performance_dashboard.png'));
