%% Simulacion Solar Off-Grid - 1 ANIO (365 Dias)
% Javier Vergara Conejero | Ingeniero Civil Eléctrico
% Configuracion: Panel 300W | Bateria 100Ah (1200Wh) | Bomba 0.5 HP
% Fuente de datos: Radiacion Global Horizontal (Tabla 3a)
% Version: CON CONSUMO VAMPIRO (Inversor + Controlador)

clear all; clc; close all;

%% 1. Parametros Tecnicos de la Carga (Bomba Humboldt 0.5 HP)
P_nom = 372.85;         
P_start = P_nom * 6;    
t_start_s = 0.5;        
P_vampiro = 0;         % Gasto base constante del equipo (Watts)

% Perfil horario base (La Ligua)
G_base = [0, 0, 0, 0, 0, 0, 2.26, 42.34, 139.29, 280.23, 419.49, 548.99, ...
          635.39, 667.99, 632.34, 551.56, 424.34, 270.66, 123.49, 33.9, 0, 0, 0, 0]; 

% 1.1 Datos Mensuales Global Horizontal
% Unidades: [kWh/m2/dia]
ins_mensual = [7.35, 6.60, 5.09, 3.79, 2.54, 2.28, 2.47, 3.26, 4.28, 5.68, 6.66, 7.41];
dias_mes = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

% Generacion del vector anual de irradiancia
G_anio = [];
for m = 1:12
    factor_escala = ins_mensual(m) / (sum(G_base)/1000); 
    G_mes = repmat(G_base * factor_escala, 1, dias_mes(m));
    G_anio = [G_anio, G_mes];
end
horas_anio = 0:(length(G_anio)-1);

%% 2. Parametros del Sistema Solar
Cap_bat_Wh = 26 * 12;  
P_panel_nom = 300;      
rendimiento = 0.85;     

SoC = zeros(1, length(G_anio));
SoC(1) = 100;           
P_gen_hist = zeros(1, length(G_anio));
E_h_hist = zeros(1, length(G_anio));

%% 3. Ciclo de Simulacion Horaria (Anual)
for h = 1:length(G_anio)
    hora_dia = mod(h-1, 24);
    
    % --- Logica de Consumo (LAVADORA ELIMINADA) ---
    if (hora_dia >= 7 && hora_dia <= 22)
        n_arranques = 20; 
        if (hora_dia == 7 || hora_dia == 20)
            t_total_regimen = (5 * 60) + (15 * 10); % Duchas
        elseif (hora_dia == 13)
            t_total_regimen = (10 * 60) + (10 * 10); % Almuerzo
        else
            % Uso estandar: 20 usos de 10 seg (Incluye hora 14)
            t_total_regimen = 20 * 10;
        end
        % Energia de bomba + 15Wh de consumo vampiro por hora
        E_h = ((n_arranques * P_start * t_start_s + (t_total_regimen - n_arranques * t_start_s) * P_nom) / 3600) + P_vampiro;
    else
        n_arranques = 5; t_total_regimen = 50;
        % Energia de bomba nocturna + 15Wh de consumo vampiro por hora
        E_h = ((n_arranques * P_start * t_start_s + (t_total_regimen - n_arranques * t_start_s) * P_nom) / 3600) + P_vampiro;
    end
    
    P_gen = P_panel_nom * (G_anio(h)/1000) * rendimiento; 
    P_gen_hist(h) = P_gen;
    E_h_hist(h) = E_h;
    
    if h > 1
        SoC(h) = SoC(h-1) + ((P_gen - E_h) / Cap_bat_Wh) * 100;
        if SoC(h) > 100, SoC(h) = 100; end
        if SoC(h) < 0, SoC(h) = 0; end
    end
end

%% 4. Resultados en Consola
E_total_kWh = sum(E_h_hist) / 1000;
costo_anual_red = E_total_kWh * 200;
E_vampiro_anio = (P_vampiro * 8760) / 1000;

fprintf('\n=================================================\n');
fprintf('   REPORTE ANUAL: LA BALLENA (CON VAMPIRO 15W)  \n');
fprintf('=================================================\n');
fprintf('Energia total (Bomba + Equipos): %.2f kWh/anio\n', E_total_kWh);
fprintf('Gasto anual solo por Inversor:   %.2f kWh/anio\n', E_vampiro_anio);
fprintf('Ahorro economico anual:          $%.0f CLP\n', costo_anual_red);
fprintf('SoC Minimo alcanzado (Invierno): %.1f %%\n', min(SoC));
fprintf('=================================================\n');

%% 5. Generacion de Graficos (Estructura Original)
figure('Color', 'w', 'Name', 'Simulacion Anual La Ballena - Huaquen', 'Position', [100 100 900 850]);

subplot(3,1,1);
area(horas_anio, G_anio, 'FaceColor', [1 0.8 0.2], 'EdgeColor', 'none');
title('Recurso Solar Disponible Anual (W/m^2)');
ylabel('Irradiancia'); grid on; xlim([0 8760]);

subplot(3,1,2);
hold on;
plot(horas_anio, P_gen_hist, 'g', 'DisplayName', 'Generacion Panel (Wh)');
plot(horas_anio, E_h_hist, 'r', 'DisplayName', 'Consumo (Bomba + Vampiro)');
title('Balance Energetico Anual');
ylabel('Energia (Wh)'); legend('Location', 'northeast'); grid on; xlim([0 8760]);

subplot(3,1,3);
plot(horas_anio, SoC, 'b', 'LineWidth', 1.5); hold on;
yline(50, 'k--', 'Recomendado (50%)', 'LineWidth', 1.2);
yline(20, 'r--', 'Limite Critico (20%)', 'LineWidth', 1.5);
title('Estado de Carga de la Bateria (SoC %)');
xlabel('Tiempo (Horas del anio)'); ylabel('% Carga');
grid on; ylim([0 110]); xlim([0 8760]);