%% Parameters
clear all;
close all;
clc;
% Define floor plan dimensions and AP coordinates
width = 8.2; % Floor plan width in meters (820 pixels = 8.2m)
height = 13.2; % Floor plan height in meters (1320 pixels = 13.2m)
resolution = 0.1; % Grid resolution in meters (10 cm)
APs = [2.10, 11.65; ... % AP1: (210, 155) pixels -> (2.10, 13.2-1.55)
       8.00, 6.20; ...  % AP2: (800, 700) pixels -> (8.00, 13.2-7.00)
       2.40, 3.80];     % AP3: (240, 940) pixels -> (2.40, 13.2-9.40)

% RSSI data at distances [1m, 2m, 3m, 5m, 6m]
rssi_data.Dialog_4G_365 = [-48.6, -60.5, -61.8, -67.4, -64.3]; % AP1
rssi_data.Dialog_4G_721 = [-41.7, -52.9, -55.5, -72.9, -64.5]; % AP2
rssi_data.SLT_MOBITEL_4G = [-39.8, -53.4, -52.8, -68.3, -67.4]; % AP3
distances = [1, 2, 3, 5, 6]; % Corresponding distances in meters
ap_names = {'Dialog_4G_365', 'Dialog_4G_721', 'SLT_MOBITEL_4G'}; % AP names

%% Floor Plan Setup
% Create grid for interpolation
x = 0:resolution:width; % 83 points (0 to 8.2)
y = 0:resolution:height; % 133 points (0 to 13.2)
[X, Y] = meshgrid(x, y); % X, Y: 133×83

% Prepare data points for interpolation
data_points = struct;
for ap = 1:size(APs, 1)
    [D, A] = meshgrid(distances, 0:pi/4:2*pi); % 5 distances x 9 angles = 45 points
    x_points = APs(ap, 1) + D .* cos(A);
    y_points = APs(ap, 2) + D .* sin(A);
    rssi_values = repmat(rssi_data.(ap_names{ap}), 1, length(0:pi/4:2*pi));
    data_points(ap).x = x_points(:);
    data_points(ap).y = y_points(:);
    data_points(ap).rssi = rssi_values(:);
end

%% Floor Plan Plotting
% Create a movable figure and plot rooms and corridors
set(groot, 'DefaultFigureDockControls', 'off'); % Prevent docking
set(groot, 'DefaultFigureWindowStyle', 'normal'); % Ensure standard window
figure('Position', [100, 1, 800, 1200], ...
       'DockControls', 'off', ...
       'WindowStyle', 'normal', ...
       'Units', 'pixels', ...
       'MenuBar', 'figure', ...
       'ToolBar', 'figure', ...
       'Name', 'RSSI Contours');
hold on;

% Plot rectangular floor plan boundary
rectangle('Position', [0, 0, width, height], 'EdgeColor', 'k', 'LineWidth', 2);

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

%% Visualization
% Interpolate and plot RSSI contours for each AP
colors = {'r', 'g', 'b'}; % Colors for each AP
for ap = 1:size(APs, 1)
    F = scatteredInterpolant(data_points(ap).x(:), data_points(ap).y(:), data_points(ap).rssi(:), 'linear', 'none');
    RSSI = F(X, Y);
    min_rssi = min(data_points(ap).rssi(:));
    max_rssi = max(data_points(ap).rssi(:));
    contour_levels = min_rssi:5:max_rssi; % Contour every 5 dB
    contour(X, Y, RSSI, contour_levels, 'LineColor', colors{ap}, 'LineWidth', 1.5, ...
            'LabelSpacing', 500, 'DisplayName', sprintf('AP%d', ap));
    plot(APs(ap, 1), APs(ap, 2), 'ko', 'MarkerFaceColor', colors{ap}, 'MarkerSize', 8);
    text(APs(ap, 1) + 0.2, APs(ap, 2), sprintf('AP%d', ap), 'FontSize', 12, 'Color', colors{ap});
end

% Configure plot
axis equal;
axis([0 width 0 height]);
xlabel('X (m)');
ylabel('Y (m)');
title('RSSI Contours for APs (Data-Based)');
legend('show', 'Location', 'southoutside');
grid on;
hold off;