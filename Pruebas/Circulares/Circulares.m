% === Archivos de entrada ===
fixfile   = 'PrimeraFix_k3.5.txt';      % Archivo del Fixposition
reachfile = 'PrimeraReach_k3.5.txt';    % Archivo del Reach M2
gpxfile   = '23Abril2025_PruebaCirc1TierraLaentic.gpx';

% === Leer datos de sensores desde archivos separados ===
data_fix = readmatrix(fixfile);
data_reach = readmatrix(reachfile);

% Extraer columnas adecuadas
fix_lat  = data_fix(:,15);
fix_lon  = data_fix(:,16);
reach_lat = data_reach(:,15);
reach_lon = data_reach(:,16);

% === Leer GPX como estructura XML ===
gpx = readstruct(gpxfile, FileType="xml");
trkpts = gpx.trk.trkseg.trkpt;
N = length(trkpts);

ref_lat = zeros(N,1);
ref_lon = zeros(N,1);
for i = 1:N
    ref_lat(i) = trkpts(i).latAttribute;
    ref_lon(i) = trkpts(i).lonAttribute;
end

% === Conversión a coordenadas planas (X,Y) ===
lat0 = mean(ref_lat);
lon0 = mean(ref_lon);
R = 6371000; % Radio terrestre en metros

x_ref = (deg2rad(ref_lon - lon0)) * R * cos(deg2rad(lat0));
y_ref = (deg2rad(ref_lat - lat0)) * R;
x_reach = (deg2rad(reach_lon - lon0)) * R * cos(deg2rad(lat0));
y_reach = (deg2rad(reach_lat - lat0)) * R;
x_fix = (deg2rad(fix_lon - lon0)) * R * cos(deg2rad(lat0));
y_fix = (deg2rad(fix_lat - lat0)) * R;

% === Función auxiliar ===
function d = point_to_segment_dist(x0, y0, x1, y1, x2, y2)
    d = abs((y2 - y1) * x0 - (x2 - x1) * y0 + x2*y1 - y2*x1) / sqrt((y2 - y1)^2 + (x2 - x1)^2);
    dot1 = (x0 - x1)*(x2 - x1) + (y0 - y1)*(y2 - y1);
    dot2 = (x0 - x2)*(x1 - x2) + (y0 - y2)*(y1 - y2);
    if dot1 < 0
        d = sqrt((x0 - x1)^2 + (y0 - y1)^2);
    elseif dot2 < 0
        d = sqrt((x0 - x2)^2 + (y0 - y2)^2);
    end
end

% === Función para calcular errores por punto ===
function errors_cm = compute_errors(x_sensor, y_sensor, x_ref, y_ref)
    M = length(x_sensor);
    N = length(x_ref);
    errors = zeros(M,1);
    for j = 1:M
        dists = arrayfun(@(i) point_to_segment_dist(x_sensor(j), y_sensor(j), ...
            x_ref(i), y_ref(i), x_ref(i+1), y_ref(i+1)), 1:N-1);
        errors(j) = min(dists);
    end
    errors_cm = errors * 100;
end

% === Calcular errores ===
errors_reach_cm = compute_errors(x_reach, y_reach, x_ref, y_ref);
errors_fix_cm   = compute_errors(x_fix,   y_fix,   x_ref, y_ref);

% === Calcular índices de error máximo === 
[max_reach, idx_max_reach] = max(errors_reach_cm);
[max_fix, idx_max_fix] = max(errors_fix_cm);

% === Graficar errores punto a punto ===
figure;
plot(errors_reach_cm, 'r'); hold on;
plot(errors_fix_cm, 'b');

% Marcar errores máximos con estrellas y texto 
plot(idx_max_reach, max_reach, 'ro', 'MarkerSize', 6.5, 'MarkerFaceColor', 'r');
text(idx_max_reach, max_reach + 2, sprintf('Max Reach: %.2f cm', max_reach), 'Color', 'r');

plot(idx_max_fix, max_fix, 'bo', 'MarkerSize', 6.5, 'MarkerFaceColor', 'b');
text(idx_max_fix, max_fix + 2, sprintf('Max Fix: %.2f cm', max_fix), 'Color', 'b');

xlabel('Índice de punto del sensor');
ylabel('Error (cm)');
legend('Reach M+', 'Fixposition');
title('Error punto a trayectoria de referencia');
grid on;

% === Graficar trayectorias ===
figure;
plot(x_ref, y_ref, 'k--', 'LineWidth', 2.5); hold on;
plot(x_reach, y_reach, 'r-', 'LineWidth', 1);
plot(x_fix, y_fix, 'b-', 'LineWidth', 1);

% Marcar las posiciones del error máximo en las trayectorias 
plot(x_reach(idx_max_reach), y_reach(idx_max_reach), 'ro', 'MarkerSize', 6.5, 'MarkerFaceColor', 'r');
text(x_reach(idx_max_reach), y_reach(idx_max_reach) + 1, 'Max Reach Error', 'Color', 'r');

plot(x_fix(idx_max_fix), y_fix(idx_max_fix), 'bo', 'MarkerSize', 6.5, 'MarkerFaceColor', 'b');
text(x_fix(idx_max_fix), y_fix(idx_max_fix) + 1, 'Max Fix Error', 'Color', 'b');

xlabel('X (m)');
ylabel('Y (m)');
title('Comparación de trayectorias: Referencia, Reach M+ y Fixposition');
legend('Referencia GPX', 'Reach M+', 'Fixposition');
axis equal;
grid on;
