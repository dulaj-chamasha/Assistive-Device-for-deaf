%% 1. Initialization and Data Setup
% Purpose: Clear workspace and define input data for calibration and
% trilateration, including RSSI measurements, anchor positions, and true
% position.
% Inputs: None (hardcoded example data).
% Outputs: 
%   - rssi_data: Calibration RSSI for each AP at specified distances.
%   - distances, log_distances: Calibration distances (meters) and their log10.
%   - rssi_variance: Variance of RSSI measurements (placeholder).
%   - los_nlos: LOS/NLOS flags (all LOS for simplicity).
%   - anchor_positions: (x, y) coordinates of APs.
%   - rssi_measured: Example RSSI measurements for trilateration.
%   - measured_pos: True position (3.5, 1.8) for visualization.
% Dependencies: None.
% Notes: 
%   - Replace rssi_data, anchor_positions, rssi_measured with actual data.
%   - Uncomment CSV loading for real calibration data.
clear all;
clc;

% Calibration RSSI data (dBm) for each AP at specified distances
% Format: [RSSI at 1m, 2m, 3m, 5m, 6m]
rssi_data.Dialog_4G_365  = [-48.6, -60.5, -61.8, -67.4, -64.3];
rssi_data.Dialog_4G_721  = [-41.7, -52.9, -55.5, -72.9, -64.5];
rssi_data.SLT_MOBITEL_4G = [-39.8, -53.4, -52.8, -68.3, -67.4];

% Calibration distances (meters)
distances = [1.0, 2.0, 3.0, 5.0, 6.0];

% Transform distances to log10 for regression
log_distances = log10(distances);

% Variance of RSSI measurements (placeholder; replace with actual data)
rssi_variance.Dialog_4G_365  = ones(size(distances)) * 2.0;
rssi_variance.Dialog_4G_721  = ones(size(distances)) * 2.0;
rssi_variance.SLT_MOBITEL_4G = ones(size(distances)) * 2.0;

% LOS/NLOS flags (1 for LOS, 0 for NLOS; all LOS for simplicity)
los_nlos.Dialog_4G_365  = ones(size(distances));
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

% Anchor positions (x, y) in meters (example; replace with actual)
anchor_positions = [
    0, 0;   % Dialog_4G_365
    10, 0;  % Dialog_4G_721
    5, 8    % SLT_MOBITEL_4G
];

% Example RSSI measurements from target device (dBm; replace with actual)
rssi_measured = [
    -55.0;  % Dialog_4G_365
    -60.0;  % Dialog_4G_721
    -58.0   % SLT_MOBITEL_4G
];

% Measured (true) position for visualization (meters)
measured_pos = [3.5, 1.8]; % [x, y]

% Define figure position (same for all figures)
fig_position = [100, 100, 600, 600]; % [left, bottom, width, height]

%% 2. Calibration of Path Loss Model
% Purpose: Calibrate the path loss model RSSI = A - 10*n*log10(d) for each
% AP by fitting a linear regression to RSSI vs. log10(Distance). Plot
% calibration results in two figures.
% Equation: RSSI = A - 10*n*log10(d)
% Reference: Whitehouse, K., et al. (2007). A Practical Evaluation of Radio
%   Signal Strength for Ranging-based Localization. ACM SIGMOBILE Mobile
%   Computing and Communications Review, 11(1), 41–52.
%   DOI: 10.1145/1232717.1232722 [Eq. (1)].
%   Elicit PDF: Available via ACM Digital Library; search "A Practical
%   Evaluation of Radio Signal Strength" on https://elicit.com.
% Inputs:
%   - rssi_data, log_distances, distances, rssi_variance, los_nlos: From Section 1.
% Outputs:
%   - calibration_results: Struct with A, n, and variances for each AP.
%   - Figures: 'rssi_log_distance.png', 'rssi_vs_distance.png'.
% Dependencies: Section 1 (data setup).

% Input validation
if isempty(distances) || length(distances) < 2
    error('At least two distance points are required for calibration.');
end
if any(cellfun(@isempty, struct2cell(rssi_data)))
    error('RSSI data for one or more APs is empty.');
end

% List of APs for iteration
ap_names = fieldnames(rssi_data);

% Arrays to store calibration results
calibration_results = struct();
A_values = zeros(length(ap_names), 1);
n_values = zeros(length(ap_names), 1);
rmse_values = zeros(length(ap_names), 1);

% Create figure for RSSI vs. log10(Distance)
figure('Position', fig_position);
hold on;

% Fit linear regression for each AP and plot
for i = 1:length(ap_names)
    ap_name = ap_names{i};
    rssi_values = rssi_data.(ap_name);
    variances = rssi_variance.(ap_name);
    los_flags = los_nlos.(ap_name);
    
    % Separate LOS and NLOS data (unused in current fit)
    los_idx = los_flags == 1;
    nlos_idx = los_flags == 0;
    
    % Fit all data with linear regression
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

% Create figure for RSSI vs. Distance
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

% Print calibration results
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

%% 3. Span Threshold Filtering
% Purpose: Simulate a time series of RSSI measurements for each AP (replace
% with actual data) and apply a moving average filter to reduce noise.
% Inputs:
%   - rssi_measured: Baseline RSSI values for simulation (from Section 1).
%   - ap_names: List of APs (from Section 2).
% Outputs:
%   - rssi_time_series: Simulated RSSI time series (num_APs x num_samples).
%   - rssi_filtered: Smoothed RSSI values (one per AP).
% Dependencies: Section 1 (rssi_measured), Section 7 (span_threshold_filter).
% Notes:
%   - Simulates 10 samples per AP with Gaussian noise (std = 2 dBm).
%   - Replace rssi_time_series with actual RSSI measurements.

% Simulate RSSI time series (replace with actual data)
num_samples = 10; % Number of RSSI samples per AP
rssi_noise_std = 2.0; % Standard deviation of RSSI noise (dBm)
rssi_time_series = zeros(length(ap_names), num_samples);
for i = 1:length(ap_names)
    rssi_time_series(i, :) = rssi_measured(i) + rssi_noise_std * randn(1, num_samples);
end

% Apply Span Threshold Filter
span = 3; % Filter window size (adjustable)
rssi_filtered = zeros(length(ap_names), 1);
for i = 1:length(ap_names)
    rssi_filtered(i) = span_threshold_filter(rssi_time_series(i, :), span);
end

%% 4. Distance Estimation
% Purpose: Convert unfiltered and filtered RSSI measurements to distances
% using the calibrated path loss model d = 10^((A - RSSI)/(10*n)).
% Equation: d = 10^((A - RSSI)/(10*n))
% Reference: Whitehouse, K., et al. (2007). A Practical Evaluation of Radio
%   Signal Strength for Ranging-based Localization. ACM SIGMOBILE Mobile
%   Computing and Communications Review, 11(1), 41–52.
%   DOI: 10.1145/1232717.1232722 [Eq. (1)].
%   Elicit PDF: Available via ACM Digital Library; search "A Practical
%   Evaluation of Radio Signal Strength" on https://elicit.com.
% Inputs:
%   - rssi_measured, rssi_filtered: Unfiltered and filtered RSSI (Sections 1, 3).
%   - calibration_results, ap_names: Calibration parameters (Section 2).
% Outputs:
%   - distances_est: Estimated distances from unfiltered RSSI.
%   - distances_est_filtered: Estimated distances from filtered RSSI.
% Dependencies: Section 2 (calibration_results), Section 3 (rssi_filtered),
%   Section 7 (rssi_to_distance).

% Convert unfiltered RSSI to distances
distances_est = zeros(length(ap_names), 1);
for i = 1:length(ap_names)
    ap_name = ap_names{i};
    A = calibration_results.(ap_name).A;
    n = calibration_results.(ap_name).n;
    distances_est(i) = rssi_to_distance(rssi_measured(i), A, n);
end

% Convert filtered RSSI to distances
distances_est_filtered = zeros(length(ap_names), 1);
for i = 1:length(ap_names)
    ap_name = ap_names{i};
    A = calibration_results.(ap_name).A;
    n = calibration_results.(ap_name).n;
    distances_est_filtered(i) = rssi_to_distance(rssi_filtered(i), A, n);
end

%% 5. Basic Trilateration (Unfiltered and Filtered)
% Purpose: Estimate the target position using Basic Trilateration with
% unfiltered and filtered RSSI distances. Solve a linear system A*x = b.
% Equation: A * [x, y]^T = b
% Reference: Savvides, A., et al. (2001). Dynamic Fine-Grained Localization in
%   Ad-Hoc Networks of Sensors. Proceedings of MobiCom ’01, 166–179.
%   DOI: 10.1145/381677.381693 [Eq. (3)].
%   Elicit PDF: Available via ACM Digital Library; search "Dynamic Fine-Grained
%   Localization" on https://elicit.com.
% Inputs:
%   - anchor_positions, measured_pos: From Section 1.
%   - distances_est, distances_est_filtered: From Section 4.
% Outputs:
%   - pos_est_basic: Estimated position (unfiltered).
%   - pos_est_basic_filtered: Estimated position (filtered).
%   - Figures: 'basic_trilateration_result.png', 'basic_trilateration_filtered.png'.
% Dependencies: Section 1 (anchor_positions, measured_pos), Section 4 (distances).

% Formulate linear system: A * [x, y]^T = b
A = 2 * [(anchor_positions(1,1) - anchor_positions(2,1)), (anchor_positions(1,2) - anchor_positions(2,2));
         (anchor_positions(1,1) - anchor_positions(3,1)), (anchor_positions(1,2) - anchor_positions(3,2))];

% Basic Trilateration (Unfiltered)
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

% Basic Trilateration (Filtered)
b_filtered = [(anchor_positions(1,1)^2 + anchor_positions(1,2)^2 - distances_est_filtered(1)^2) - ...
              (anchor_positions(2,1)^2 + anchor_positions(2,2)^2 - distances_est_filtered(2)^2);
              (anchor_positions(1,1)^2 + anchor_positions(1,2)^2 - distances_est_filtered(1)^2) - ...
              (anchor_positions(3,1)^2 + anchor_positions(3,2)^2 - distances_est_filtered(3)^2)];

if rank(A) == 2
    pos_est_basic_filtered = A \ b_filtered; % [x, y]
else
    warning('Anchors are collinear; using pseudo-inverse.');
    pos_est_basic_filtered = pinv(A) * b_filtered;
end

% Plot Basic Trilateration Result (Unfiltered)
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
title('Basic Trilateration Result (Unfiltered)');
legend('show', 'Location', 'best');
grid on;
axis equal;
hold off;
saveas(gcf, 'basic_trilateration_result.png');

% Plot Basic Trilateration Result (Filtered)
figure('Position', fig_position);
plot(anchor_positions(:,1), anchor_positions(:,2), 'ks', 'MarkerSize', 10, ...
    'MarkerFaceColor', 'k', 'DisplayName', 'Anchors');
hold on;
plot(pos_est_basic_filtered(1), pos_est_basic_filtered(2), 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b', ...
    'DisplayName', 'Estimated Position (Basic, Filtered)');
plot(measured_pos(1), measured_pos(2), 'g*', 'MarkerSize', 12, 'LineWidth', 2, ...
    'DisplayName', 'Measured Position');
xlabel('X (meters)');
ylabel('Y (meters)');
title('Basic Trilateration Result (Filtered)');
legend('show', 'Location', 'best');
grid on;
axis equal;
hold off;
saveas(gcf, 'basic_trilateration_filtered.png');

% Print Basic Trilateration Results
fprintf('\nBasic Trilateration Result (Unfiltered):\n');
fprintf('Measured Position: (%.2f, %.2f) meters\n', measured_pos(1), measured_pos(2));
fprintf('Estimated Position: (%.2f, %.2f) meters\n', pos_est_basic(1), pos_est_basic(2));
fprintf('\nBasic Trilateration Result (Filtered):\n');
fprintf('Measured Position: (%.2f, %.2f) meters\n', measured_pos(1), measured_pos(2));
fprintf('Estimated Position: (%.2f, %.2f) meters\n', pos_est_basic_filtered(1), pos_est_basic_filtered(2));

%% 6. WLS Trilateration (Unfiltered and Filtered)
% Purpose: Estimate the target position using Weighted Least Squares (WLS)
% Trilateration with unfiltered and filtered RSSI distances. Uses numerical
% optimization (fmincon) to minimize the cost function:
%   S(x, y) = sum_{i=1}^3 w_i * (sqrt((x - x_i)^2 + (y - y_i)^2) - d_i)^2
% Reference: Li, Z., Zhang, Y., & Li, D. (2020). An Improved Weighted Least
%   Squares Method for Mobile Positioning in NLOS Environments. IEEE Access,
%   8, 193607–193616. DOI: 10.1109/ACCESS.2020.3032803 [Eq. (7)].
%   Elicit PDF: Available via IEEE Xplore; search "An Improved Weighted Least
%   Squares Method for Mobile Positioning" on https://elicit.com.
% Weights are computed as:
%   w_i = 1 / sigma_d_i^2, where sigma_d_i = d_i * (ln(10) / (10 * n_i)) * sigma_RSSI
% Reference: Pivato, P., Palopoli, L., & Petri, D. (2011). Accuracy of RSS-Based
%   Centroid Localization Algorithms in an Indoor Environment. IEEE Transactions
%   on Instrumentation and Measurement, 60(10), 3451–3460.
%   DOI: 10.1109/TIM.2011.2134890 [Eq. (12)].
%   Elicit PDF: Available via IEEE Xplore; search "Accuracy of RSS-Based
%   Centroid Localization" on https://elicit.com.
% Inputs:
%   - anchor_positions, measured_pos: From Section 1.
%   - distances_est, distances_est_filtered: From Section 4.
%   - calibration_results, ap_names: From Section 2.
% Outputs:
%   - pos_est_wls: Estimated position (unfiltered).
%   - pos_est_wls_filtered: Estimated position (filtered).
%   - Figures: 'wls_trilateration_result.png', 'wls_trilateration_filtered.png'.
% Dependencies: Section 1, 2, 4, 7 (wls_cost).

% WLS Trilateration (Unfiltered)
% Step 1: Compute weights based on distance uncertainties
weights = zeros(length(ap_names), 1);
for i = 1:length(ap_names)
    ap_name = ap_names{i};
    A = calibration_results.(ap_name).A;
    n = calibration_results.(ap_name).n;
    variances = calibration_results.(ap_name).variances;
    % RSSI standard deviation (mean of sqrt(variances))
    sigma_rssi = mean(sqrt(variances));
    % Distance uncertainty: sigma_d_i = d_i * (ln(10) / (10 * n_i)) * sigma_RSSI
    sigma_d = distances_est(i) * (log(10) / (10 * n)) * sigma_rssi;
    % Weight: w_i = 1 / sigma_d_i^2
    weights(i) = 1 / (sigma_d^2);
end

% Step 2: Set up numerical optimization
initial_guess = mean(anchor_positions, 1); % Centroid of anchors
options = optimoptions('fmincon', 'Display', 'off');

% Step 3: Minimize S(x, y) using numerical optimization (Unfiltered)
[pos_est_wls, ~] = fmincon(@(pos) wls_cost(pos, anchor_positions, distances_est, weights), ...
    initial_guess, [], [], [], [], [], [], [], options);

% WLS Trilateration (Filtered)
% Step 1: Compute weights for filtered distances
weights_filtered = zeros(length(ap_names), 1);
for i = 1:length(ap_names)
    ap_name = ap_names{i};
    A = calibration_results.(ap_name).A;
    n = calibration_results.(ap_name).n;
    variances = calibration_results.(ap_name).variances;
    sigma_rssi = mean(sqrt(variances));
    sigma_d = distances_est_filtered(i) * (log(10) / (10 * n)) * sigma_rssi;
    weights_filtered(i) = 1 / (sigma_d^2);
end

% Step 2: Minimize S(x, y) using numerical optimization (Filtered)
[pos_est_wls_filtered, ~] = fmincon(@(pos) wls_cost(pos, anchor_positions, distances_est_filtered, weights_filtered), ...
    initial_guess, [], [], [], [], [], [], [], options);

% Step 3: Plot WLS Trilateration Result (Unfiltered)
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
title('WLS Trilateration Result (Unfiltered)');
legend('show', 'Location', 'best');
grid on;
axis equal;
hold off;
saveas(gcf, 'wls_trilateration_result.png');

% Plot WLS Trilateration Result (Filtered)
figure('Position', fig_position);
plot(anchor_positions(:,1), anchor_positions(:,2), 'ks', 'MarkerSize', 10, ...
    'MarkerFaceColor', 'k', 'DisplayName', 'Anchors');
hold on;
plot(pos_est_wls_filtered(1), pos_est_wls_filtered(2), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r', ...
    'DisplayName', 'Estimated Position (WLS, Filtered)');
plot(measured_pos(1), measured_pos(2), 'g*', 'MarkerSize', 12, 'LineWidth', 2, ...
    'DisplayName', 'Measured Position');
xlabel('X (meters)');
ylabel('Y (meters)');
title('WLS Trilateration Result (Filtered)');
legend('show', 'Location', 'best');
grid on;
axis equal;
hold off;
saveas(gcf, 'wls_trilateration_filtered.png');

% Step 4: Print WLS Trilateration Results
fprintf('\nWLS Trilateration Result (Unfiltered):\n');
fprintf('Measured Position: (%.2f, %.2f) meters\n', measured_pos(1), measured_pos(2));
fprintf('Estimated Position: (%.2f, %.2f) meters\n', pos_est_wls(1), pos_est_wls(2));
fprintf('\nWLS Trilateration Result (Filtered):\n');
fprintf('Measured Position: (%.2f, %.2f) meters\n', measured_pos(1), measured_pos(2));
fprintf('Estimated Position: (%.2f, %.2f) meters\n', pos_est_wls_filtered(1), pos_est_wls_filtered(2));

%% 7. Function Definitions
% Purpose: Define helper functions for RSSI-to-distance conversion, WLS cost
% function, and span threshold filtering.
% Inputs: Called by Sections 3, 4, 5, 6.
% Outputs: Function results (distances, costs, filtered RSSI).
% Dependencies: None.

function d = rssi_to_distance(rssi, A, n)
    % Convert RSSI to distance using the path loss model
    % Equation: d = 10^((A - RSSI)/(10*n))
    % Reference: Whitehouse, K., et al. (2007). A Practical Evaluation of
    %   Radio Signal Strength for Ranging-based Localization. ACM SIGMOBILE
    %   Mobile Computing and Communications Review, 11(1), 41–52.
    %   DOI: 10.1145/1232717.1232722 [Eq. (1)].
    %   Elicit PDF: Available via ACM Digital Library; search "A Practical
    %   Evaluation of Radio Signal Strength" on https://elicit.com.
    % Inputs:
    %   - rssi: RSSI value (dBm)
    %   - A: Reference RSSI at 1m (dBm)
    %   - n: Path loss exponent
    % Output: d: Estimated distance (meters)
    d = 10.^((A - rssi) / (10 * n));
end

function cost = wls_cost(pos, anchors, distances, weights)
    % WLS cost function for trilateration
    % Equation: S(x, y) = sum_{i=1}^3 w_i * (sqrt((x - x_i)^2 + (y - y_i)^2) - d_i)^2
    % Reference: Li, Z., Zhang, Y., & Li, D. (2020). An Improved Weighted
    %   Least Squares Method for Mobile Positioning in NLOS Environments.
    %   IEEE Access, 8, 193607–193616. DOI: 10.1109/ACCESS.2020.3032803 [Eq. (7)].
    %   Elicit PDF: Available via IEEE Xplore; search "An Improved Weighted
    %   Least Squares Method for Mobile Positioning" on https://elicit.com.
    % Inputs:
    %   - pos: Estimated position [x, y]
    %   - anchors: Anchor positions (num_APs x 2)
    %   - distances: Estimated distances (num_APs x 1)
    %   - weights: Weights w_i = 1 / sigma_d_i^2 (num_APs x 1)
    % Output: cost: Weighted sum of squared errors
    x = pos(1);
    y = pos(2);
    est_distances = sqrt(sum((anchors - [x, y]).^2, 2));
    errors = est_distances - distances;
    cost = sum(weights .* errors.^2);
end

function rssi_filtered = span_threshold_filter(rssi_series, span)
    % Apply moving average filter to RSSI time series
    % Inputs:
    %   - rssi_series: RSSI measurements over time (1 x num_samples)
    %   - span: Filter window size
    % Output: rssi_filtered: Smoothed RSSI value
    window = ones(span, 1) / span;
    rssi_smoothed = filter(window, 1, rssi_series);
    rssi_filtered = rssi_smoothed(end);
end