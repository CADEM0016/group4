%% Size a B747-8F at a Mach number of 0.85
% This script sizes the 747-8F using the B747 class and specific aerodynamics

clear; clc;

fprintf('=== SIZING B747-8F ===\n\n');

% Instantiate an instance of the B747 class
ADP = B747.ADP();

% Set Top Level Aircraft Requirements (TLAR)
% Using B777F TLAR as base but updating for 747 performance
ADP.TLAR = cast.TLAR.B777F(); 
ADP.TLAR.M_c = 0.85;  % 747 cruise Mach
ADP.TLAR.Range = 8130 * 1852; % ~8,130 nm range (typical 747-8F)
ADP.TLAR.Payload = 134000;    % ~134 tonnes max structural payload

fprintf('Key Parameters set in ADP:\n');
fprintf('  MTOM: %.0f kg\n', ADP.MTOM);
fprintf('  Wing Area: %.0f m²\n', ADP.WingArea);
fprintf('  Span: %.1f m\n', ADP.Span);

% -------------------------------- Sizing --------------------------------
% Call B747.Size which uses the UpdateAero function from B747 class
% preventing the B777 defaults from overwriting our work
fprintf('\nStarting Sizing Loop...\n');
ADP = B747.Size(ADP);
fprintf('Sizing Complete.\n\n');

%% build the "Sized" geometry and plot it
[B7Geom,B7Mass] = B747.BuildGeometry(ADP); % get list of components geometries and masses

% plot the geometry
f = figure(1);
clf;
% Try to load 747 image if available, otherwise just plot geometry
try
    % img = imread('B747_planform.png'); 
    % imshow(img, 'XData', [0 76.3], 'YData', [-68.4 68.4]/2); 
    % hold on;
catch
end

cast.draw(B7Geom,B7Mass)
ax = gca;
ax.XAxis.Visible = "on";
ax.YAxis.Visible = "on";
axis equal
ylim([-0.6 0.6]*ADP.Span)
title('B747-8F Sized Geometry');
xlabel('Length [m]');
ylabel('Span [m]');

% print some key data points
d = B7Mass.GetData;
fprintf('=== FINAL SIZED PARAMETERS ===\n');
fprintf('MTOM:      %0.0f t\n', ADP.MTOM/1e3);
fprintf('Fuel Mass: %0.0f t\n', ADP.Mf_Fuel*ADP.MTOM/1e3);
fprintf('Payload:   %0.0f t\n', ADP.TLAR.Payload/1e3);

% Check Aerodynamics
CL_check = 0.5;
CD_check = ADP.AeroPolar.CD(CL_check);
fprintf('\n=== AERODYNAMICS CHECK ===\n');
fprintf('CD0 (Zero-Lift):   %0.4f\n', ADP.AeroPolar.CD(0));
fprintf('CD (CL=0.5):       %0.4f\n', CD_check);
fprintf('L/D (CL=0.5):      %0.2f\n', CL_check/CD_check);
fprintf('\n');

% Check Engine Configuration
engines = B7Geom(contains([B7Geom.Name], "Engine"));
fprintf('=== PROPULSION CHECK ===\n');
fprintf('Number of Engines: %d\n', length(engines));
