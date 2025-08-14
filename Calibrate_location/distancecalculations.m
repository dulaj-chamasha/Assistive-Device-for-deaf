clear all;
close all;
clc;
% Circle center
h = 2.10; % x-coordinate of center in meters
k = 10.65; % y-coordinate of center in meters

% Radii to evaluate
radii = 1:8; % r = 1, 2, 3, 4, 5, 6, 7, 8 meters

% Given x and y values
x_given = 1:8; % x = 1, 2, 3, 4, 5, 6, 7, 8 meters
y_given = 1:12; % y = 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 meters

% Initialize output
fprintf('Circle Center: (%.2f, %.2f) meters\n\n', h, k);

% Calculate y for given x
fprintf('Points (x, y1, y2) for given x:\n');
for x = x_given
    fprintf('x = %.0f m:\n', x);
    for r = radii
        discriminant = r^2 - (x - h)^2;
        if discriminant >= 0
            y1 = k - sqrt(discriminant);
            y2 = k + sqrt(discriminant);
            fprintf('  r = %.0f m: (%.2f, %.2f), (%.2f, %.2f)\n', r, x, y1, x, y2);
        else
            fprintf('  r = %.0f m: No real solutions\n', r);
        end
    end
    fprintf('\n');
end

% Calculate x for given y
fprintf('Points (x1, y, x2, y) for given y:\n');
for y = y_given
    fprintf('y = %.0f m:\n', y);
    for r = radii
        discriminant = r^2 - (y - k)^2;
        if discriminant >= 0
            x1 = h - sqrt(discriminant);
            x2 = h + sqrt(discriminant);
            fprintf('  r = %.0f m: (%.2f, %.2f), (%.2f, %.2f)\n', r, x1, y, x2, y);
        else
            fprintf('  r = %.0f m: No real solutions\n', r);
        end
    end
    fprintf('\n');
end