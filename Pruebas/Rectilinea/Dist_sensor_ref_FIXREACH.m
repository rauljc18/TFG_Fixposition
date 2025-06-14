% === Archivos de entrada ===
fixfile   = 'TerceraPruebaFix_k2.5.txt';      % Archivo del Fixposition
reachfile = 'TerceraPruebaReach_k2.5.txt';    % Archivo del Reach M2
gpxfile   = '28ABRIL2025_PruebaParking2.gpx';

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

% === Calcular RMSE ===
rmse_reach_cm = sqrt(mean(errors_reach_cm.^2));
rmse_fix_cm   = sqrt(mean(errors_fix_cm.^2));
disp(['RMSE Reach M+: ', num2str(rmse_reach_cm), ' cm']);
disp(['RMSE Fixposition: ', num2str(rmse_fix_cm), ' cm']);

% === Estadísticas básicas ===
mean_reach = mean(errors_reach_cm);
std_reach  = std(errors_reach_cm);
max_reach  = max(errors_reach_cm);
min_reach  = min(errors_reach_cm);

mean_fix = mean(errors_fix_cm);
std_fix  = std(errors_fix_cm);
max_fix  = max(errors_fix_cm);
min_fix  = min(errors_fix_cm);

disp('--- Estadísticas Reach M+ ---');
disp(['Media: ', num2str(mean_reach), ' cm']);
disp(['Desviación estándar: ', num2str(std_reach), ' cm']);
disp(['Máximo: ', num2str(max_reach), ' cm']);
disp(['Mínimo: ', num2str(min_reach), ' cm']);

disp('--- Estadísticas Fixposition ---');
disp(['Media: ', num2str(mean_fix), ' cm']);
disp(['Desviación estándar: ', num2str(std_fix), ' cm']);
disp(['Máximo: ', num2str(max_fix), ' cm']);
disp(['Mínimo: ', num2str(min_fix), ' cm']);

% === Porcentaje de errores bajo un umbral ===
threshold_cm = 2;
pct_reach = sum(errors_reach_cm < threshold_cm) / length(errors_reach_cm) * 100;
pct_fix = sum(errors_fix_cm < threshold_cm) / length(errors_fix_cm) * 100;

disp(['Porcentaje de errores < ', num2str(threshold_cm), ' cm (Reach): ', num2str(pct_reach), '%']);
disp(['Porcentaje de errores < ', num2str(threshold_cm), ' cm (Fixposition): ', num2str(pct_fix), '%']);

% === Graficar errores punto a punto ===
% === Graficar errores punto a trayectoria de referencia ===
figure;
plot(errors_reach_cm, 'r'); hold on;
plot(errors_fix_cm, 'b');

% Encontrar máximos y sus índices
[max_reach_val, max_reach_idx] = max(errors_reach_cm);
[max_fix_val, max_fix_idx] = max(errors_fix_cm);

% Marcar puntos máximos en la gráfica
plot(max_reach_idx, max_reach_val, 'ro', 'MarkerFaceColor', 'r');
plot(max_fix_idx, max_fix_val, 'bo', 'MarkerFaceColor', 'b');

% Añadir texto explicativo
text(max_reach_idx, max_reach_val + 0.5, ...
    sprintf('Max Reach: %.1f cm', max_reach_val), ...
    'Color', 'r', 'FontSize', 11, 'HorizontalAlignment', 'center');

text(max_fix_idx, max_fix_val + 0.5, ...
    sprintf('Max Fix: %.1f cm', max_fix_val), ...
    'Color', 'b', 'FontSize', 11, 'HorizontalAlignment', 'center');

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
xlabel('X (m)');
ylabel('Y (m)');
title('Comparación de trayectorias: Referencia, Reach M+ y Fixposition');
legend('Referencia GPX', 'Reach M+', 'Fixposition');
axis equal;
grid on;



% Definir los mismos bordes de los bins
edges = linspace(0, max([errors_reach_cm; errors_fix_cm]), 50); % 50 bins comunes

% Histograma sincronizado
figure;
histogram(errors_reach_cm, edges, 'FaceColor', 'r', 'FaceAlpha', 0.6); hold on;
histogram(errors_fix_cm,   edges, 'FaceColor', 'b', 'FaceAlpha', 0.6);
xlabel('Error (cm)');
ylabel('Frecuencia');
legend('Reach M+', 'Fixposition');
title('Histograma de errores');
grid on;

% === CDF de errores ===
figure;
cdfplot(errors_reach_cm); hold on;
cdfplot(errors_fix_cm);
legend('Reach M+', 'Fixposition');
xlabel('Error (cm)');
ylabel('Probabilidad acumulada');
title('CDF de errores');
grid on;

% === Curva suavizada del error (media móvil) ===
figure;
plot(movmean(errors_reach_cm, 10), 'r'); hold on;
plot(movmean(errors_fix_cm, 10), 'b');
xlabel('Índice temporal');
ylabel('Error suavizado (cm)');
legend('Reach M+', 'Fixposition');
title('Evolución temporal del error (media móvil)');
grid on;
