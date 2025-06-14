% === ARCHIVO DE ENTRADA ===
data_file = 'Pruebaestatica_FixGpsPrincipal.txt';  

% === LEER DATOS ===
data = readmatrix(data_file);
lat = data(:,10);
lon = data(:,11);

% === REFERENCIA: CENTROIDE DE LA NUBE ===
lat0 = mean(lat);
lon0 = mean(lon);
R = 6371000; % Radio medio de la Tierra en metros

% === CONVERSIÓN A COORDENADAS PLANAS (X,Y) en CM ===
x_cm = (deg2rad(lon - lon0)) * R * cos(deg2rad(lat0)) * 100; % en cm
y_cm = (deg2rad(lat - lat0)) * R * 100;                      % en cm

% Convertir a mm para la gráfica
x = x_cm * 10; % mm
y = y_cm * 10; % mm

% === Calcular centroide (en XY) en mm ===
mu = [mean(x), mean(y)];

% === NUBE DE PUNTOS CON CENTROIDE en mm ===
figure;
scatter(x, y, 43,'r', 'filled'); hold on;
plot(mu(1), mu(2), 'kx', 'MarkerSize', 13, 'LineWidth', 2);
xlabel('X (mm)');
ylabel('Y (mm)');
title('Nube de puntos: Prueba Reach M+ (mm)');
legend('Posiciones', 'Centroide');
axis equal;
grid on;
xtickformat('%.0f');
ytickformat('%.0f');


% === DISTANCIA AL CENTROIDE EN CM ===
dist = sqrt((x - mu(1)).^2 + (y - mu(2)).^2);  % Ya está en cm

% === HISTOGRAMA DEL ERROR RADIAL EN CM ===
figure;
histogram(dist, 30, 'FaceColor', 'r', 'FaceAlpha', 0.6)
xlabel('Error radial (mm)');
ylabel('Frecuencia');
title('Histograma del error radial Reach M+');
grid on;

% === ESTADÍSTICAS ===
rmse = sqrt(mean(dist.^2));
std_dev = std(dist);
max_error = max(dist);

disp('--- Estadísticas prueba estática ---');
disp(['RMSE: ', num2str(rmse, '%.2f'), ' mm']);
disp(['Desviación estándar radial: ', num2str(std_dev, '%.2f'), ' mm']);
disp(['Error máximo radial: ', num2str(max_error, '%.2f'), ' mm']);