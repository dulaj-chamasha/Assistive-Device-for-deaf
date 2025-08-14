% Clear workspace and command window
clear all;
clc;

% Averaged RSSI data (your actual measurements)
% Format: [RSSI at 1m, 2m, 3m, 5m, 6m] in dBm
rssi_data.Dialog_4G_365  = [-48.6, -60.5, -61.8, -67.4, -64.3];
rssi_data.Dialog_4G_721  = [-41.7, -52.9, -55.5, -72.9, -64.5];
rssi_data.SLT_MOBITEL_4G = [-39.8, -53.4, -52.8, -68.3, -67.4];

% Distances in meters
distances = [1.0, 2.0, 3.0, 5.0, 6.0];

% Transform distances to log10
log_distances = log10(distances);

% Optional: Load data from CSV (uncomment to use)
%{
% Expected CSV format: columns 'distance', 'rssi1', 'rssi2', 'rssi3'
data = readtable('rssi_data.csv');
distances = data.distance;
rssi_data.Dialog_4G_365  = data.rssi1;
rssi_data.Dialog_4G_721  = data.rssi2;
rssi_data.SLT_MOBITEL_4G = data.rssi3;
log_distances = log10(distances);
%}

% Create a new figure
figure('Position', [100, 100, 800, 600]);

% List of APs for iteration
ap_names = fieldnames(rssi_data);

% Fit linear regression for each AP and plot
hold on;
for i = 1:length(ap_names)
    ap_name = ap_names{i};
    rssi_values = rssi_data.(ap_name);
    
    % Linear regression: RSSI = A - 10*n*log10(distance)
    coeffs = polyfit(log_distances, rssi_values, 1);
    A = coeffs(2); % Intercept
    slope = coeffs(1);
    n = -slope / 10.0; % Path loss exponent
    
    % Predicted RSSI values
    y_pred = polyval(coeffs, log_distances);
    
    % Plot data points
    scatter(log_distances, rssi_values, 50, 'filled', 'DisplayName', [ap_name ' Data']);
    
    % Plot regression line
    plot(log_distances, y_pred, 'LineWidth', 2, 'DisplayName', sprintf('%s Fit (A=%.1f, n=%.2f)', ap_name, A, n));
end

% Customize plot
xlabel('log10(Distance) (log10 meters)');
ylabel('RSSI (dBm)');
title('RSSI vs. log10(Distance) with Linear Regression');
legend('show', 'Location', 'best');
grid on;
hold off;

% Save plot to file
saveas(gcf, 'rssi_regression.png');

% Print A and n
fprintf('Calibration Results:\n');
for i = 1:length(ap_names)
    ap_name = ap_names{i};
    rssi_values = rssi_data.(ap_name);
    coeffs = polyfit(log_distances, rssi_values, 1);
    A = coeffs(2);
    n = -coeffs(1) / 10.0;
    fprintf('%s: A = %.1f dBm, n = %.2f\n', ap_name, A, n);
    Average_A = 
end