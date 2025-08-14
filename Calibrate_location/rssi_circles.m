%% Parameters
clear all;
close all;
clc;

% Define log-distance path loss model parameters and floor plan dimensions
RSSI_d0 = -44.18; % RSSI at reference distance (d0 = 1m) in dBm (calibrated)
n = 3.09; % Path loss exponent (calibrated)
d0 = 1; % Reference distance in meters
width = 8.2; % Floor plan width in meters (820 pixels = 8.2m)
height = 13.2; % Floor plan height in meters (1320 pixels = 13.2m)
resolution = 0.1; % Grid resolution in meters (10 cm)
RSSI_drops = [10, 20, 30]; % RSSI drops in dB for contours
colors = {'r', 'g', 'b'}; % Colors: Red for 10 dB, Green for 20 dB, Blue for 30 dB

% Calculate distances for RSSI drops
distances = d0 * 10.^(RSSI_drops / (10 * n));
disp('Distances for RSSI drops:');
disp(table(RSSI_drops', distances', 'VariableNames', {'RSSI_Drop_dB', 'Distance_m'}));

%% Floor Plan Setup
% Define AP coordinates and create grid
APs = [2.10, 11.65; ... % AP1: (210, 155) pixels -> (2.10, 13.2-1.55)
       8.00, 6.20; ...  % AP2: (800, 700) pixels -> (8.00, 13.2-7.00)
       2.40, 3.80];     % AP3: (240, 940) pixels -> (2.40, 13.2-9.40)
x = 0:resolution:width; % 83 points (0 to 8.2)
y = 0:resolution:height; % 133 points (0 to 13.2)
[X, Y] = meshgrid(x, y); % X, Y: 133×83

% Debug: Check grid dimensions
disp('Grid dimensions:');
disp(['size(X) = ', num2str(size(X))]);
disp(['size(Y) = ', num2str(size(Y))]);

%% Floor Plan Plotting
% Create a movable figure and plot rooms and corridors
set(groot, 'DefaultFigureDockControls', 'off'); % Prevent docking
set(groot, 'DefaultFigureWindowStyle', 'normal'); % Ensure standard window
figure('Position', [100, 100, 800, 1200], ...
       'DockControls', 'off', ...
       'WindowStyle', 'normal', ...
       'Units', 'pixels', ...
       'MenuBar', 'figure', ...
       'ToolBar', 'figure', ...
       'Name', 'RSSI Contours');
hold on;

% Corridor 2
rectangle('Position', [0, 10.2, 5.4, 3], 'FaceColor', [0.94, 0.94, 0.94], 'EdgeColor', 'k', 'LineWidth', 2);
text(2.7, 11.85, 'Corridor 2', 'FontSize', 12, 'HorizontalAlignment', 'center');

% Bedroom 4
rectangle('Position', [5.4, 10.2, 2.8, 3], 'FaceColor', 'w', 'EdgeColor', 'k', 'LineWidth', 2);
text(6.8, 11.7, 'Bedroom 4', 'FontSize', 12, 'HorizontalAlignment', 'center');

% Dining Room
rectangle('Position', [4.1, 7, 4.1, 3.2], 'FaceColor', 'w', 'EdgeColor', 'k', 'LineWidth', 2);
text(6.15, 8.6, 'Dining Room', 'FontSize', 12, 'HorizontalAlignment', 'center');

% Bedroom 3
rectangle('Position', [0, 6.75, 4.1, 3.45], 'FaceColor', 'w', 'EdgeColor', 'k', 'LineWidth', 2);
text(2.05, 8.74, 'Bedroom 3', 'FontSize', 12, 'HorizontalAlignment', 'center');

% Bedroom 1
rectangle('Position', [0, 3.6, 3.2, 3], 'FaceColor', 'w', 'EdgeColor', 'k', 'LineWidth', 2);
text(1.6, 5.1, 'Bedroom 1', 'FontSize', 12, 'HorizontalAlignment', 'center');

% Bedroom 2
rectangle('Position', [0, 0.6, 3.2, 3], 'FaceColor', 'w', 'EdgeColor', 'k', 'LineWidth', 2);
text(1.6, 2.1, 'Bedroom 2', 'FontSize', 12, 'HorizontalAlignment', 'center');

% Living Room
rectangle('Position', [3.2, 1.6, 5, 5.2], 'FaceColor', 'w', 'EdgeColor', 'k', 'LineWidth', 2);
text(5.7, 4.4, 'Living Room', 'FontSize', 12, 'HorizontalAlignment', 'center');

% Corridor
rectangle('Position', [3.2, 0, 5, 0.8], 'FaceColor', [0.94, 0.94, 0.94], 'EdgeColor', 'k', 'LineWidth', 2);
text(5.7, 0.4, 'Corridor', 'FontSize', 12, 'HorizontalAlignment', 'center');

%% RSSI Calculation
% Compute RSSI for each AP
RSSI = zeros(size(X, 1), size(X, 2), size(APs, 1)); % Store RSSI: 133×83×3
disp('RSSI array dimensions:');
disp(['size(RSSI) = ', num2str(size(RSSI))]);

for ap = 1:size(APs, 1)
    % Calculate distance from AP to each grid point
    D = sqrt((X - APs(ap, 1)).^2 + (Y - APs(ap, 2)).^2);
    
    % Debug: Check D dimensions
    disp(['AP', num2str(ap), ' distance matrix size:']);
    disp(['size(D) = ', num2str(size(D))]);
    
    % Calculate RSSI using log-distance path loss model
    RSSI(:,:,ap) = RSSI_d0 - 10 * n * log10(D / d0);
    RSSI(D < 0.01, ap) = RSSI_d0; % Avoid log(0) at AP location
end

%% Visualization
% Plot RSSI contours and AP positions
for ap = 1:size(APs, 1)
    % Plot contours for 10 dB, 20 dB, 30 dB drops
    for i = 1:length(RSSI_drops)
        contour(X, Y, RSSI(:,:,ap), [RSSI_d0 - RSSI_drops(i)], 'LineColor', colors{i}, 'LineWidth', 1.5, ...
                'LabelSpacing', 500, 'DisplayName', sprintf('AP%d -%ddB', ap, RSSI_drops(i)));
    end
    
    % Plot AP position
    plot(APs(ap, 1), APs(ap, 2), 'ko', 'MarkerFaceColor', 'c', 'MarkerSize', 8);
    text(APs(ap, 1) + 0.2, APs(ap, 2), sprintf('AP%d', ap), 'FontSize', 12);
end

% Configure plot
axis equal;
axis([0 width 0 height]);
xlabel('X (m)');
ylabel('Y (m)');
title('RSSI Contours for APs (Log-Distance Path Loss Model, Calibrated)');
legend('show', 'Location', 'southoutside');
grid on;
hold off;

%% Example Dataset
% Generate and save simulated RSSI measurements
rng(42); % Set seed for reproducibility
num_samples = 10;
example_data = struct;
example_data.x = width * rand(num_samples, 1);
example_data.y = height * rand(num_samples, 1);
example_data.rssi = zeros(num_samples, size(APs, 1));

for i = 1:num_samples
    for ap = 1:size(APs, 1)
        d = sqrt((example_data.x(i) - APs(ap, 1))^2 + (example_data.y(i) - APs(ap, 2))^2);
        example_data.rssi(i, ap) = RSSI_d0 - 10 * n * log10(d / d0) + randn(1) * 5; % Add noise
    end
end

% Save and display dataset
save('example_rssi_data.mat', 'example_data');
disp('Example Dataset:');
disp(table(example_data.x, example_data.y, example_data.rssi(:,1), example_data.rssi(:,2), example_data.rssi(:,3), ...
           'VariableNames', {'X_m', 'Y_m', 'RSSI_AP1_dBm', 'RSSI_AP2_dBm', 'RSSI_AP3_dBm'}));