% === Archivos de entrada ===
fixfile        = 'BAJADA.txt';          % Archivo de Bajada
reachfile      = 'SUBIDA.txt';        % Archivo de Subida
gpxfile        = 'BAJADATUNEL_12JUNIO.gpx'; % GPX referencia de bajada
reach_gpxfile  = 'SUBIDATUNEL_12JUNIO.gpx';                % GPX referencia de subida

% === Leer datos de sensores ===
data_fix = readmatrix(fixfile);
data_reach = readmatrix(reachfile);

% Extraer columnas adecuadas
fix_lat   = data_fix(:,15);
fix_lon   = data_fix(:,16);
reach_lat = data_reach(:,15);
reach_lon = data_reach(:,16);

% === Leer GPX referencia de bajada ===
gpx = readstruct(gpxfile, FileType="xml");
trkpts = gpx.trk.trkseg.trkpt;
N = length(trkpts);
ref_lat = zeros(N,1);
ref_lon = zeros(N,1);
for i = 1:N
    ref_lat(i) = trkpts(i).latAttribute;
    ref_lon(i) = trkpts(i).lonAttribute;
end

% === Leer GPX referencia de subida ===
gpx_reach = readstruct(reach_gpxfile, FileType="xml");
trkpts_reach = gpx_reach.trk.trkseg.trkpt;
N_reach = length(trkpts_reach);
ref_lat_reach = zeros(N_reach,1);
ref_lon_reach = zeros(N_reach,1);
for i = 1:N_reach
    ref_lat_reach(i) = trkpts_reach(i).latAttribute;
    ref_lon_reach(i) = trkpts_reach(i).lonAttribute;
end

% === Conversión a coordenadas planas (X,Y) ===
lat0 = mean(ref_lat);  % Punto de referencia común
lon0 = mean(ref_lon);
R = 6371000; % Radio terrestre en metros

% Referencia Bajada
x_ref = (deg2rad(ref_lon - lon0)) * R * cos(deg2rad(lat0));
y_ref = (deg2rad(ref_lat - lat0)) * R;

% Referencia Subida
x_ref_reach = (deg2rad(ref_lon_reach - lon0)) * R * cos(deg2rad(lat0));
y_ref_reach = (deg2rad(ref_lat_reach - lat0)) * R;

% Trayectorias sensores
x_reach = (deg2rad(reach_lon - lon0)) * R * cos(deg2rad(lat0));
y_reach = (deg2rad(reach_lat - lat0)) * R;
x_fix   = (deg2rad(fix_lon - lon0)) * R * cos(deg2rad(lat0));
y_fix   = (deg2rad(fix_lat - lat0)) * R;

% === Función auxiliar para distancia punto a segmento ===
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

% === Función para calcular errores punto a punto ===
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
errors_reach_cm = compute_errors(x_reach, y_reach, x_ref_reach, y_ref_reach);
errors_fix_cm   = compute_errors(x_fix,   y_fix,   x_ref,        y_ref);

% === Calcular errores máximos ===
[max_reach, idx_max_reach] = max(errors_reach_cm);
[max_fix, idx_max_fix] = max(errors_fix_cm);

% === Graficar errores punto a punto ===
figure;
plot(errors_reach_cm, 'r'); hold on;
plot(errors_fix_cm, 'b');

% Marcar errores máximos
plot(idx_max_reach, max_reach, 'ro', 'MarkerSize', 6.5, 'MarkerFaceColor', 'r');
text(idx_max_reach, max_reach + 2, sprintf('Max Reach: %.2f cm', max_reach), 'Color', 'r');

plot(idx_max_fix, max_fix, 'bo', 'MarkerSize', 6.5, 'MarkerFaceColor', 'b');
text(idx_max_fix, max_fix + 2, sprintf('Max Fix: %.2f cm', max_fix), 'Color', 'b');

xlabel('Índice de punto del sensor');
ylabel('Error (cm)');
legend('Reach M+', 'Fixposition');
title('Error punto a trayectoria de referencia');
grid on;

% === Graficar trayectorias===
figure;

h_ref1 = plot(x_ref, y_ref, 'k--', 'LineWidth', 2.5); hold on;
h_ref2 = plot(x_ref_reach, y_ref_reach, 'k--', 'LineWidth', 2.5);
h_reach = plot(x_reach, y_reach, 'm-', 'LineWidth', 1.5);          % Reach: magenta
h_fix = plot(x_fix, y_fix, 'Color', [0.1 0.6 0.1], 'LineWidth', 1.5);  % Fix: verde claro

% Marcar primer punto de Fix como "Inicio" con punto verde gordo
plot(x_fix(1), y_fix(1), 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 8);

% Texto "Inicio" centrado encima del punto, con un pequeño espacio
text(x_fix(1), y_fix(1) + 0.5, 'Inicio', 'Color', [0.1 0.6 0.1], 'FontWeight', 'bold', ...
    'FontSize', 12, ...      % <-- Aquí agregas el tamaño de fuente
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');

% Marcar último punto de Reach como "Fin" con punto magenta gordo
plot(x_reach(end), y_reach(end), 'mo', 'MarkerFaceColor', 'm', 'MarkerSize', 8);

% Texto "Fin" centrado debajo del punto, con un pequeño espacio
text(x_reach(end), y_reach(end) - 0.5, 'Fin', 'Color', 'm', 'FontWeight', 'bold', ...
    'FontSize', 12, ...      % <-- Aquí también
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');

xlabel('X (m)');
ylabel('Y (m)');
title('Comparación de trayectorias: Referencia, Bajada y Subida');
axis equal;
grid on;

% Aquí solo tomamos uno de los dos handles de referencia para la leyenda
legend([h_ref1, h_fix, h_reach], ...
    {'Trayectoria de referencia', 'Trayectoria real de bajada', 'Trayectoria real de subida'}, ...
    'Location', 'best');
