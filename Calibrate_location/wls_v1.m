% Clear workspace and command window
clear all;
clc;

% Averaged RSSI data (in dBm) for each AP at specified distances
% Format: [RSSI at 1m, 2m, 3m, 5m, 6m]
rssi_data.Dialog_4G_365  = [-48.6, -60.5, -61.8, -67.4, -64.3];
rssi_data.Dialog_4G_721  = [-41.7, -52.9, -55.5, -72.9, -64.5];
rssi_data.SLT_MOBITEL_4G = [-39.8, -53.4, -52.8, -68.3, -67.4];

% Distances in meters
distances = [1.0, 2.0, 3.0, 5.0, 6.0];

% Transform distances to log10
log_distances = log10(distances);

% Optional: Variance of RSSI measurements (if raw data is available)
rssi_variance.Dialog_4G_365  = ones(size(distances)) * 2.0; % Placeholder
rssi_variance.Dialog_4G_721  = ones(size(distances)) * 2.0;
rssi_variance.SLT_MOBITEL_4G = ones(size(distances)) * 2.0;

% Optional: LOS/NLOS flags (1 for LOS, 0 for NLOS) for each distance
los_nlos.Dialog_4G_365  = ones(size(distances)); % All LOS for simplicity
los_nlos.Dialog_4G_721  = ones(size(distances));
los_nlos.SLT_MOBITEL_4G = ones(size(distances));

% Optional: Load data from CSV (uncomment to use)
% Expected CSV format: columns 'distance', 'rssi1', 'rssi2', 'rssi3', 'var1', 'var2', 'var3', 'los_nlos1', 'los_nlos2', 'los_nlos3'
%{
data = readtable('rssi_data.csv');
distances = data.distance;
rssi_data.Dialog_4G_365  = data.rssi1;
rssi_data.Dialog_4G_721  = data.rssi2;
rssi_data.SLT_MOBITEL_4G = data.rssi3;
rssi_variance.Dialog_4G_365  = data.var1;
rssi_variance.Dialog_4G_721  = data.var2;
rssi_variance.SLT_MOBITEL_4G = data.var3;
los_nlos.Dialog_4G_365  = data.los_nlos1;
los_nlos.Dialog_4G_721  = data.los_nlos2;
los_nlos.SLT_MOBITEL_4G = data.los_nlos3;
log_distances = log10(distances);
%}

% Input validation
if isempty(distances) || length(distances) < 2
    error('At least two distance points are required for calibration.');
end
if any(cellfun(@isempty, struct2cell(rssi_data)))
    error('RSSI data for one or more APs is empty.');
end

% Define figure position (same for all figures)
fig_position = [100, 100, 600, 600]; % [left, bottom, width, height]

% Create figure for RSSI vs. log10(Distance) calibration plot
figure('Position', fig_position);

% List of APs for iteration
ap_names = fieldnames(rssi_data);

% Arrays to store calibration results
calibration_results = struct();
A_values = zeros(length(ap_names), 1);
n_values = zeros(length(ap_names), 1);
rmse_values = zeros(length(ap_names), 1);

% Fit linear regression for each AP and plot
hold on;
for i = 1:length(ap_names)
    ap_name = ap_names{i};
    rssi_values = rssi_data.(ap_name);
    variances = rssi_variance.(ap_name);
    los_flags = los_nlos.(ap_name);
    
    % Separate LOS and NLOS data (if needed)
    los_idx = los_flags == 1;
    nlos_idx = los_flags == 0; % Fixed: Use los_flags instead of los_nlos
    
    % Fit all data together
    coeffs = polyfit(log_distances, rssi_values, 1);
    A = coeffs(2); % Intercept (P_0)
    slope = coeffs(1);
    n = -slope / 10.0; % Path loss exponent
    
    % Store calibration results
    A_values(i) = A;
    n_values(i) = n;
    calibration_results.(ap_name).A = A;
    calibration_results.(ap_name).n = n;
    calibration_results.(ap_name).variances = variances;
    
    % Predicted RSSI values
    y_pred = polyval(coeffs, log_distances);
    
    % Calculate RMSE
    rmse = sqrt(mean((rssi_values - y_pred).^2));
    rmse_values(i) = rmse;
    
    % Plot data points with error bars
    errorbar(log_distances, rssi_values, sqrt(variances), 'o', 'MarkerSize', 8, ...
        'DisplayName', [ap_name ' Data']);
    
    % Plot regression line
    plot(log_distances, y_pred, 'LineWidth', 2, ...
        'DisplayName', sprintf('%s Fit (A=%.1f, n=%.2f, RMSE=%.2f)', ap_name, A, n, rmse));
end

% Customize RSSI vs. log10(Distance) plot
xlabel('log10(Distance) (log10 meters)');
ylabel('RSSI (dBm)');
title('RSSI vs. log10(Distance) with Linear Regression');
legend('show', 'Location', 'best');
grid on;
hold off;

% Save RSSI vs. log10(Distance) plot
saveas(gcf, 'rssi_log_distance.png');

% Create figure for RSSI vs. Distance calibration plot
figure('Position', fig_position);
hold on;
for i = 1:length(ap_names)
    ap_name = ap_names{i};
    rssi_values = rssi_data.(ap_name);
    variances = rssi_variance.(ap_name);
    A = calibration_results.(ap_name).A;
    n = calibration_results.(ap_name).n;
    
    % Plot measured data points with error bars
    errorbar(distances, rssi_values, sqrt(variances), 'o', 'MarkerSize', 8, ...
        'DisplayName', [ap_name ' Data']);
    
    % Plot fitted path loss model
    d_fine = 0.1:0.1:6.0; % Fine grid for smooth curve
    rssi_fit = A - 10 * n * log10(d_fine);
    plot(d_fine, rssi_fit, 'LineWidth', 2, ...
        'DisplayName', sprintf('%s Fit (A=%.1f, n=%.2f)', ap_name, A, n));
end

% Customize RSSI vs. Distance plot
xlabel('Distance (meters)');
ylabel('RSSI (dBm)');
title('RSSI vs. Distance with Path Loss Model');
legend('show', 'Location', 'best');
grid on;
hold off;

% Save RSSI vs. Distance plot
saveas(gcf, 'rssi_vs_distance.png');

% Print individual calibration results
fprintf('Calibration Results (Individual APs):\n');
for i = 1:length(ap_names)
    fprintf('%s: A = %.1f dBm, n = %.2f, RMSE = %.2f dBm\n', ...
        ap_names{i}, A_values(i), n_values(i), rmse_values(i));
end

% Calculate and print average A and n
average_A = mean(A_values);
average_n = mean(n_values);
fprintf('\nFinal Averages:\n');
fprintf('Average A = %.2f dBm\n', average_A);
fprintf('Average n = %.2f\n', average_n);

% Save calibration results
save('calibration_results.mat', 'calibration_results', 'average_A', 'average_n');

% Anchor positions (x, y) in meters (example; replace with actual coordinates)
anchor_positions = [
    0, 0;   % Dialog_4G_365
    10, 0;  % Dialog_4G_721
    5, 8    % SLT_MOBITEL_4G
];

% Example RSSI measurements from the target device (replace with actual)
rssi_measured = [
    -55.0;  % Dialog_4G_365
    -60.0;  % Dialog_4G_721
    -58.0   % SLT_MOBITEL_4G
];

% Measured (true) position for the example
measured_pos = [3.5, 1.8]; % [x, y] in meters

% Convert RSSI to distances
distances_est = zeros(length(ap_names), 1);
for i = 1:length(ap_names)
    ap_name = ap_names{i};
    A = calibration_results.(ap_name).A;
    n = calibration_results.(ap_name).n;
    distances_est(i) = rssi_to_distance(rssi_measured(i), A, n);
end

% Basic Trilateration
% Formulate linear system: A * [x, y]^T = b
A = 2 * [(anchor_positions(1,1) - anchor_positions(2,1)), (anchor_positions(1,2) - anchor_positions(2,2));
         (anchor_positions(1,1) - anchor_positions(3,1)), (anchor_positions(1,2) - anchor_positions(3,2))];

b = [(anchor_positions(1,1)^2 + anchor_positions(1,2)^2 - distances_est(1)^2) - ...
     (anchor_positions(2,1)^2 + anchor_positions(2,2)^2 - distances_est(2)^2);
     (anchor_positions(1,1)^2 + anchor_positions(1,2)^2 - distances_est(1)^2) - ...
     (anchor_positions(3,1)^2 + anchor_positions(3,2)^2 - distances_est(3)^2)];

% Solve linear system
if rank(A) == 2 % Check if A is invertible
    pos_est_basic = A \ b; % [x, y]
else
    warning('Anchors are collinear; using pseudo-inverse.');
    pos_est_basic = pinv(A) * b;
end

% Plot Basic Trilateration Result
figure('Position', fig_position);
plot(anchor_positions(:,1), anchor_positions(:,2), 'ks', 'MarkerSize', 10, ...
    'MarkerFaceColor', 'k', 'DisplayName', 'Anchors');
hold on;
plot(pos_est_basic(1), pos_est_basic(2), 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b', ...
    'DisplayName', 'Estimated Position (Basic)');
plot(measured_pos(1), measured_pos(2), 'g*', 'MarkerSize', 12, 'LineWidth', 2, ...
    'DisplayName', 'Measured Position');
xlabel('X (meters)');
ylabel('Y (meters)');
title('Basic Trilateration Result');
legend('show', 'Location', 'best');
grid on;
axis equal;
hold off;
saveas(gcf, 'basic_trilateration_result.png');

% Print Basic Trilateration Result
fprintf('\nBasic Trilateration Result:\n');
fprintf('Measured Position: (%.2f, %.2f) meters\n', measured_pos(1), measured_pos(2));
fprintf('Estimated Position: (%.2f, %.2f) meters\n', pos_est_basic(1), pos_est_basic(2));

% WLS Trilateration (for comparison)
% Compute weights for WLS
weights = zeros(length(ap_names), 1);
for i = 1:length(ap_names)
    ap_name = ap_names{i};
    A = calibration_results.(ap_name).A;
    n = calibration_results.(ap_name).n;
    variances = calibration_results.(ap_name).variances;
    sigma_rssi = mean(sqrt(variances));
    sigma_d = distances_est(i) * (log(10) / (10 * n)) * sigma_rssi;
    weights(i) = 1 / (sigma_d^2);
end

% Initial guess: Centroid of anchors
initial_guess = mean(anchor_positions, 1);

% Optimization options
options = optimoptions('fmincon', 'Display', 'off');

% Perform WLS optimization
[pos_est_wls, ~] = fmincon(@(pos) wls_cost(pos, anchor_positions, distances_est, weights), ...
    initial_guess, [], [], [], [], [], [], [], options);

% Plot WLS Trilateration Result
figure('Position', fig_position);
plot(anchor_positions(:,1), anchor_positions(:,2), 'ks', 'MarkerSize', 10, ...
    'MarkerFaceColor', 'k', 'DisplayName', 'Anchors');
hold on;
plot(pos_est_wls(1), pos_est_wls(2), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r', ...
    'DisplayName', 'Estimated Position (WLS)');
plot(measured_pos(1), measured_pos(2), 'g*', 'MarkerSize', 12, 'LineWidth', 2, ...
    'DisplayName', 'Measured Position');
xlabel('X (meters)');
ylabel('Y (meters)');
title('WLS Trilateration Result');
legend('show', 'Location', 'best');
grid on;
axis equal;
hold off;
saveas(gcf, 'wls_trilateration_result.png');

% Print WLS Trilateration Result
fprintf('\nWLS Trilateration Result:\n');
fprintf('Measured Position: (%.2f, %.2f) meters\n', measured_pos(1), measured_pos(2));
fprintf('Estimated Position: (%.2f, %.2f) meters\n', pos_est_wls(1), pos_est_wls(2));

% --- Function Definitions ---
function d = rssi_to_distance(rssi, A, n)
    % Convert RSSI to distance using the path loss model
    d = 10.^((A - rssi) / (10 * n));
end

function cost = wls_cost(pos, anchors, distances, weights)
    % WLS cost function for trilateration
    x = pos(1);
    y = pos(2);
    est_distances = sqrt(sum((anchors - [x, y]).^2, 2));
    errors = est_distances - distances;
    cost = sum(weights .* errors.^2);
end