%% B747 Sizing Script (Using Modified B777 Logic)
% This script runs the sizing process using your modified B777 files (Ultrafan, 747 parameters)
% but applies 747-specific requirements (TLARs) and avoids overwriting your parameters.

clear; clc; close all;

fprintf('=== Initializing B747-8F Sizing ===\n');

% 1. Create the ADP object 
% Note: Since you modified B777.ADP with 747 values (Span=71, MTOM=530t), 
% this object starts correctly.
ADP = B777.ADP();

% 2. Set Top Level Aircraft Requirements (TLAR) for 747-8F
% Using a struct instead of an object to avoid persistent field/property errors
TLAR = struct();
TLAR.M_c = 0.85;          % Cruise Mach (747 is faster)
TLAR.Range = 12200 * 1000; % Range [m] (12,200 km)
TLAR.Payload = 150000;    % Payload [kg] (150 t)
TLAR.Alt_cruise = 35000/3.28; % Cruise Altitude (~10668m)
TLAR.Alt_max = 45000/3.28;
TLAR.V_app = 150 * 0.5144; % approx
TLAR.V_ld = 140 * 0.5144; % approx
ADP.TLAR = TLAR;

fprintf('Target Parameters:\n');
fprintf('  Cruise Mach: %.2f\n', ADP.TLAR.M_c);
% 3. Configure Target 747-8F Parameters
% User specified: MTOM 530, Fuel 180, OEM 200, Payload 150
fprintf('\nConfiguring 747-8F Target State...\n');
ADP.MTOM = 530000;
ADP.Mf_Fuel = 180000 / 530000;
ADP.OEM = 200000;
ADP.WingArea = 600;
ADP.Span = 71.0;
ADP.TLAR.Payload = 150000;

% Update Loading and Thrust for display
B777.ConstraintAnalysis(ADP);
B777.UpdateAero(ADP);

fprintf('Target Configuration Set.\n');

% 4. Display Results
fprintf('\n=== TARGET CONFIGURATION ===\n');
fprintf('MTOM:      %.0f t\n', ADP.MTOM/1e3);
fprintf('Fuel Mass: %.0f t\n', ADP.Mf_Fuel * ADP.MTOM/1e3);
fprintf('OEM:       %.0f t\n', ADP.OEM/1e3);
fprintf('Payload:   150 t\n');

% Check Aerodynamics
CL_check = 0.5;
if ~isempty(ADP.AeroPolar)
    CD_check = ADP.AeroPolar.CD(CL_check);
    fprintf('\nAERODYNAMICS:\n');
    fprintf('CD0: %.4f\n', ADP.AeroPolar.CD0);
    fprintf('L/D (CL=0.5): %.2f\n', CL_check/CD_check);
else
    fprintf('\nWarning: AeroPolar is empty (Sizing might have failed early).\n');
end

% 5. Plot Geometry
fprintf('\nPlotting Geometry...\n');
[B7Geom,B7Mass] = B777.BuildGeometry(ADP); 

figure(1); clf;
cast.draw(B7Geom,B7Mass);
axis equal;
title('B747-8F Sized Configuration');
xlabel('Length [m]'); ylabel('Width [m]');
grid on;

% Save figure for verification
try
    saveas(gcf, 'Planform_747.png');
    fprintf('\nPlanform saved to Planform_747.png\n');
catch
    fprintf('\nCould not save image (headless mode?)\n');
end

fprintf('\nDone.\n');
