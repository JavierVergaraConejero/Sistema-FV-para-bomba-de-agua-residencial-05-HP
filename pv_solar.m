%% Simulacion Solar Off-Grid - 7 Dias (La Ballena - Huaquen, La Ligua)
% Javier Vergara Conejero | Ingeniero Civil Eléctrico
% Configuracion: Panel 300W | Bateria 100Ah (1200Wh) | Bomba 0.5 HP
% Version: SIN LAVADORA + CONSUMO VAMPIRO (Inversor/Controlador)
clear all; clc; close all;

%% 1. Parametros Tecnicos de la Carga (Bomba Humboldt 0.5 HP)
P_nom = 372.85;         % Potencia nominal (W)
P_start = P_nom * 6;    % Pico de arranque (~2237W)
t_start_s = 0.5;        % Duracion del pico de arranque (segundos)
P_vampiro = 0;         % Consumo base constante del inversor y control (Watts)

% Datos de Irradiancia Horaria Promedio (W/m2) - La Ligua
G_24 = [0, 0, 0, 0, 0, 0, 2.26, 42.34, 139.29, 280.23, 419.49, 548.99, ...
        635.39, 667.99, 632.34, 551.56, 424.34, 270.66, 123.49, 33.9, 0, 0, 0, 0]; 
G_semana = repmat(G_24, 1, 7); 
horas_semana = 0:167;

%% 2. Parametros del Sistema Solar
Cap_bat_Wh = 52 * 12;  % Capacidad total: 1200 Wh
P_panel_nom = 200;      % Panel Fotovoltaico de 300Wp
rendimiento = 0.85;     % Factor de perdidas (suciedad, cables, inversor)

% Inicializacion de variables de estado
SoC = zeros(1, 168);
SoC(1) = 100;           
P_gen_hist = zeros(1, 168);
E_h_hist = zeros(1, 168);

%% 3. Ciclo de Simulacion Horaria (168 Horas)
for h = 1:168
    hora_dia = mod(h-1, 24);
    
    % --- Logica de Consumo de Agua (E_h en Wh) ---
    if (hora_dia >= 7 && hora_dia <= 22) % Horario diurno
        n_arranques = 20; 
        
        if (hora_dia == 7 || hora_dia == 20)
            % Duchas: 5 min continuos + 15 usos cortos
            t_total_regimen = (5 * 60) + (15 * 10); 
        elseif (hora_dia == 13)
            % Almuerzo: 10 min cocina + 10 usos cortos
            t_total_regimen = (10 * 60) + (10 * 10);
        else
            % Uso estandar: 20 usos cortos de 10 seg (Incluye hora 14)
            t_total_regimen = 20 * 10;
        end
        
        % Calculo de Energia bomba + Consumo Vampiro (15W * 1h = 15Wh)
        E_h = ((n_arranques * P_start * t_start_s + ...
               (t_total_regimen - n_arranques * t_start_s) * P_nom) / 3600) + P_vampiro;
    else
        % Horario nocturno: 5 usos minimos
        n_arranques = 5;
        t_total_regimen = 5 * 10;
        E_h = ((n_arranques * P_start * t_start_s + ...
               (t_total_regimen - n_arranques * t_start_s) * P_nom) / 3600) + P_vampiro;
    end
    
    % --- Generacion Fotovoltaica ---
    P_gen = P_panel_nom * (G_semana(h)/1000) * rendimiento; 
    
    % Guardar datos para graficas
    P_gen_hist(h) = P_gen;
    E_h_hist(h) = E_h;
    
    % --- Balance de la Bateria (SoC) ---
    if h > 1
        SoC(h) = SoC(h-1) + ((P_gen - E_h) / Cap_bat_Wh) * 100;
        if SoC(h) > 100, SoC(h) = 100; end
        if SoC(h) < 0, SoC(h) = 0; end
    end
end

%% 4. Reporte de Resultados
E_dia_kWh = sum(E_h_hist(1:24)) / 1000;
E_mes_kWh = E_dia_kWh * 30;
precio_kwh = 200; 
costo_mensual = E_mes_kWh * precio_kwh;
fprintf('\n=================================================\n');
fprintf('   REPORTE: LA BALLENA (CON CONSUMO VAMPIRO)    \n');
fprintf('=================================================\n');
fprintf('Energia diaria (Bomba + Vampiro): %.3f kWh\n', E_dia_kWh);
fprintf('Energia mensual estimada:         %.2f kWh\n', E_mes_kWh);
fprintf('-------------------------------------------------\n');
fprintf('Costo mensual en red (CGE):       $%.0f CLP\n', costo_mensual);
fprintf('Ahorro anual con Kit Solar:       $%.0f CLP\n', costo_mensual * 12);
fprintf('SoC Minimo alcanzado:             %.1f %%\n', min(SoC));
fprintf('=================================================\n');

%% 5. Generacion de Graficos
figure('Color', 'w', 'Name', 'Simulacion Off-Grid La Ballena - Huaquén', 'Position', [100 100 900 850]);
subplot(3,1,1);
area(horas_semana, G_semana, 'FaceColor', [1 0.8 0.2], 'EdgeColor', [0.8 0.6 0]);
title('Recurso Solar Disponible en La Ballena - Huaquén (W/m^2)');
ylabel('Irradiancia'); grid on;

subplot(3,1,2);
hold on;
area(horas_semana, P_gen_hist, 'FaceColor', [0.4 0.9 0.4], 'FaceAlpha', 0.5, 'DisplayName', 'Generacion Panel (Wh)');
plot(horas_semana, E_h_hist, 'r', 'LineWidth', 1.5, 'DisplayName', 'Consumo (Bomba + Vampiro)');
title('Balance Energetico Horario: Pgen vs Eh');
ylabel('Energia (Wh)'); legend('Location', 'northeast'); grid on;

subplot(3,1,3);
plot(horas_semana, SoC, 'b', 'LineWidth', 2.5); hold on;
yline(50, 'k--', 'Recomendado (50%)', 'LineWidth', 1.2);
yline(20, 'r--', 'Limite Critico (20%)', 'LineWidth', 1.5);
title('Estado de Carga de la Bateria (SoC %)');
xlabel('Tiempo (Horas de la semana)'); ylabel('% Carga');
grid on; ylim([0 110]);