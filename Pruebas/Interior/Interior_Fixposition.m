% === Archivos de entrada ===
fixfile = 'RECORRIDO_INTERIOR_vuelta.txt';
gpxfile = '6Junio2025_INTERIORVUELTA.gpx';

% === Leer datos de sensores ===
data = readmatrix(fixfile);
fix_lat = data(:,15);
fix_lon = data(:,16);

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
errors_fix_cm = compute_errors(x_fix, y_fix, x_ref, y_ref);

% === Calcular RMSE ===
rmse_fix_cm = sqrt(mean(errors_fix_cm.^2));
disp(['RMSE Fixposition: ', num2str(rmse_fix_cm), ' cm']);

% === Estadísticas básicas ===
mean_fix = mean(errors_fix_cm);
std_fix  = std(errors_fix_cm);
max_fix  = max(errors_fix_cm);
min_fix  = min(errors_fix_cm);

disp('--- Estadísticas Fixposition ---');
disp(['Media: ', num2str(mean_fix), ' cm']);
disp(['Desviación estándar: ', num2str(std_fix), ' cm']);
disp(['Máximo: ', num2str(max_fix), ' cm']);
disp(['Mínimo: ', num2str(min_fix), ' cm']);

% === Porcentaje de errores bajo un umbral ===
threshold_cm = 50;
pct_fix = sum(errors_fix_cm < threshold_cm) / length(errors_fix_cm) * 100;
disp(['Porcentaje de errores < ', num2str(threshold_cm), ' cm (Fixposition): ', num2str(pct_fix), '%']);

% === Graficar errores punto a punto ===
figure;
plot(errors_fix_cm, 'b');
xlabel('Índice de punto del sensor');
ylabel('Error (cm)');
legend('Fixposition');
title('Error punto a trayectoria de referencia');
grid on;

% === Graficar trayectorias ===
figure;
p1 = plot(x_ref, y_ref, 'k--', 'LineWidth', 2); hold on;
p2 = plot(x_fix, y_fix, 'b-', 'LineWidth', 1);

xlabel('X (m)');
ylabel('Y (m)');
title('Comparación de trayectorias: Referencia vs Fixposition');
axis equal;
grid on;


% === Histograma de errores ===
figure;
histogram(errors_fix_cm, 50, 'FaceColor', 'b', 'FaceAlpha', 0.6);
xlabel('Error (cm)');
ylabel('Frecuencia');
legend('Fixposition');
title('Histograma de errores');
grid on;

% === CDF de errores ===
figure;
cdfplot(errors_fix_cm);
legend('Fixposition');
xlabel('Error (cm)');
ylabel('Probabilidad acumulada');
title('CDF de errores');
grid on;

% === Curva suavizada del error (media móvil) ===
figure;
plot(movmean(errors_fix_cm, 10), 'b');
xlabel('Índice temporal');
ylabel('Error suavizado (cm)');
legend('Fixposition');
title('Evolución temporal del error (media móvil)');
grid on;
