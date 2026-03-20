%  LandingGear_Standalone.m
%
%  Configuration: 
%    Main Landing Gear : 4 bogies x 6 wheels = 24 wheels total
%    Nose Landing Gear : 1 strut  x 2 wheels = 2  wheels total
%    Based on modified B747-8F parameters


clear; clc; close all;

fprintf('=========================================================\n');
fprintf('  CADEM0016 - Landing Gear Sizing Analysis\n');
fprintf('  University of Bristol - Group 3\n');
fprintf('  Configuration: 4x6 Main + 1x2 Nose (Modified B747-8F)\n');
fprintf('=========================================================\n\n');

%  SECTION 1: AIRCRAFT DESIGN PARAMETERS

fprintf('--- Aircraft Design Parameters ---\n');

% --- Mass parameters ---
MTOM_kg         = 530000;     % [kg]   Maximum Take-Off Mass  (your design)
MLM_kg          = 370000;     % [kg]   Maximum Landing Mass   (your design)
OEM_kg          = 200000;     % [kg]   Operational Empty Mass
payload_max_kg  = 150000;     % [kg]   Maximum payload
g               = 9.81;       % [m/s2] Gravitational acceleration

% --- Fuselage geometry ---
L_fus           = 68.4;       % [m]    Total fuselage length
x_nose          = 0.0;        % [m]    Nose position (origin)
x_tail          = 68.4;       % [m]    Tail tip position

% --- Wing position ---
x_wing_LE       = 27.0;       % [m]    Wing leading edge root position from nose

% --- Centre of Mass (CoM) limits ---
% Forward and aft CoM limits as fraction of fuselage length from nose
x_CoM_fwd       = 0.38 * L_fus;  % [m]  Forward CoM limit
x_CoM_aft       = 0.44 * L_fus;  % [m]  Aft CoM limit
x_CoM_nom       = 0.41 * L_fus;  % [m]  Nominal CoM (mean cruise)

% --- Engine parameters ---
engine_diameter  = 4.38;       % [m]    Engine fan diameter (GE9X class)
engine_clearance = 0.9;      % [m]    Required ground clearance under engine
                              %        FAR-25: typically 18 inches = 0.457 m

% --- Tail geometry (for tail strike check) ---
tail_strike_angle = 12.0;     % [deg]  Maximum tail strike angle (pitch at rotation)
x_tail_contact    = 65.0;     % [m]    Tail contact point from nose
h_tail_contact    = 1.8;      % [m]    Height of tail contact point above fuselage bottom

% --- Runway / airport parameters ---
% ICAO Code E taxi limit: max wingspan 65m, main gear span < 14m
max_gear_span_m  = 14.0;      % [m]    Maximum main gear lateral span (ICAO Code E)

% --- Tyre parameters (6-wheel bogie, B747-8F class) ---
% Standard H49x19.0-22 or similar for heavy widebody
tyre_diameter    = 1.27;      % [m]    Tyre outer diameter  (~50 inches)
tyre_width       = 0.483;     % [m]    Tyre section width   (~19 inches)
tyre_pressure    = 1.55e6;    % [Pa]   Tyre inflation pressure (~225 psi)

% --- Sink rate and landing dynamics ---
V_sink           = 3.0;       % [m/s]  Design sink rate (CS-25: 3.0 m/s)
lambda           = 1.5;       % [-]    Landing reaction factor (CS-25 typical range 1.0-2.0)
                              %        lambda=1.0: pure energy absorption
                              %        lambda=1.5: typical for large transport
eta_shock        = 0.80;      % [-]    Shock absorber efficiency (typical 0.75-0.85)
eta_tyre         = 0.47;      % [-]    Tyre compression efficiency (typical 0.45-0.50)

% --- Material properties ---
% Main strut: high-strength steel (300M / 4340)
sigma_yield_MPa  = 1650;      % [MPa]  Yield strength 300M steel
rho_steel        = 7850;      % [kg/m3] Steel density
safety_factor    = 1.5;       % [-]    CS-25 ultimate load factor

% --- Class I/II empirical factors (Raymer Table 15.2) ---
% Landing gear mass as fraction of MTOM
% For large transport: MLG ~3.0-4.5%, NLG ~0.8-1.2% of MTOM
MLG_mass_fraction = 0.038;    % [-]    Main landing gear / MTOM
NLG_mass_fraction = 0.010;    % [-]    Nose landing gear / MTOM

fprintf('  MTOM                    : %.1f tonnes\n', MTOM_kg/1000);
fprintf('  MLM                     : %.1f tonnes\n', MLM_kg/1000);
fprintf('  OEM                     : %.1f tonnes\n', OEM_kg/1000);
fprintf('  Fuselage length         : %.1f m\n',      L_fus);
fprintf('  CoM range               : %.2f - %.2f m from nose\n', x_CoM_fwd, x_CoM_aft);
fprintf('  Engine fan diameter     : %.2f m\n',      engine_diameter);
fprintf('  Engine clearance req.   : %.3f m\n',      engine_clearance);
fprintf('  Tail strike angle       : %.1f deg\n',    tail_strike_angle);
fprintf('  Design sink rate        : %.1f m/s\n',    V_sink);
fprintf('  Landing reaction factor : %.2f\n\n',      lambda);

%% =========================================================================
%  SECTION 2: WHEEL AND TYRE SIZING
%  Determines if the chosen configuration (24 MLG + 2 NLG wheels)

fprintf('=========================================================\n');
fprintf('  SECTION 2: WHEEL AND TYRE SIZING\n');
fprintf('=========================================================\n\n');

% --- Configuration ---
N_MLG_struts    = 4;          % Number of main gear struts (bogies)
N_wheels_bogie  = 6;          % Wheels per bogie
N_MLG_wheels    = N_MLG_struts * N_wheels_bogie;   % = 24 total MLG wheels
N_NLG_wheels    = 2;          % Nose gear wheels
N_total_wheels  = N_MLG_wheels + N_NLG_wheels;     % = 26 total

fprintf('Landing Gear Configuration:\n');
fprintf('  Main Landing Gear : %d struts x %d wheels = %d wheels\n', ...
    N_MLG_struts, N_wheels_bogie, N_MLG_wheels);
fprintf('  Nose Landing Gear : 1 strut  x %d wheels = %d wheels\n', ...
    N_NLG_wheels, N_NLG_wheels);
fprintf('  TOTAL             : %d wheels\n\n', N_total_wheels);

% --- Load per tyre ---
% MLG carries approximately 92-95% of aircraft weight
% NLG carries approximately 5-8%
% At MTOM (most critical for tyre sizing)
MLG_load_fraction = 0.925;    % [-]  Fraction of weight on main gear
NLG_load_fraction = 0.075;    % [-]  Fraction of weight on nose gear

W_total_N         = MTOM_kg * g;                          % [N] Total weight
W_MLG_total_N     = MLG_load_fraction * W_total_N;        % [N] On all MLG
W_NLG_total_N     = NLG_load_fraction * W_total_N;        % [N] On NLG

W_per_MLG_wheel_N = W_MLG_total_N / N_MLG_wheels;        % [N] Per MLG wheel
W_per_NLG_wheel_N = W_NLG_total_N / N_NLG_wheels;        % [N] Per NLG wheel

W_per_MLG_wheel_kg = W_per_MLG_wheel_N / g;              % [kg] Per MLG wheel
W_per_NLG_wheel_kg = W_per_NLG_wheel_N / g;              % [kg] Per NLG wheel

fprintf('Load Distribution at MTOM:\n');
fprintf('  Total weight            : %.1f kN  (%.1f tonnes)\n', ...
    W_total_N/1e3, MTOM_kg/1000);
fprintf('  MLG total load          : %.1f kN  (%.0f%% of total)\n', ...
    W_MLG_total_N/1e3, MLG_load_fraction*100);
fprintf('  NLG total load          : %.1f kN  (%.0f%% of total)\n', ...
    W_NLG_total_N/1e3, NLG_load_fraction*100);
fprintf('  Load per MLG wheel      : %.2f kN  (%.0f kg)\n', ...
    W_per_MLG_wheel_N/1e3, W_per_MLG_wheel_kg);
fprintf('  Load per NLG wheel      : %.2f kN  (%.0f kg)\n\n', ...
    W_per_NLG_wheel_N/1e3, W_per_NLG_wheel_kg);

% --- Tyre contact patch and pressure check ---
% Contact patch area: A = F / p_inflation
A_contact_MLG = W_per_MLG_wheel_N / tyre_pressure;       % [m2]
A_contact_NLG = W_per_NLG_wheel_N / tyre_pressure;       % [m2]

% Equivalent contact patch dimensions (assume elliptical)
a_MLG = sqrt(A_contact_MLG / pi) * 1.5;   % semi-major axis [m]
b_MLG = A_contact_MLG / (pi * a_MLG);     % semi-minor axis [m]

fprintf('Tyre Contact Patch:\n');
fprintf('  MLG tyre size           : %.2f m dia x %.3f m wide\n', ...
    tyre_diameter, tyre_width);
fprintf('  MLG contact area        : %.4f m2 per tyre\n', A_contact_MLG);
fprintf('  NLG contact area        : %.4f m2 per tyre\n', A_contact_NLG);
fprintf('  MLG inflation pressure  : %.2f MPa  (%.0f psi)\n\n', ...
    tyre_pressure/1e6, tyre_pressure/6894.76);

% --- Mass per tyre check (flotation benchmark) ---
% Rule of thumb for heavy transport: ~30,000-40,000 kg per main tyre
fprintf('Flotation Check (mass per main tyre):\n');
fprintf('  Mass per MLG tyre       : %.0f kg  ', W_per_MLG_wheel_kg);
if W_per_MLG_wheel_kg <= 40000
    fprintf('[OK - within typical 40,000 kg limit]\n\n');
else
    fprintf('[WARNING - exceeds typical 40,000 kg limit, check flotation]\n\n');
end

%% =========================================================================
%  SECTION 3: GEAR PLACEMENT - LONGITUDINAL POSITIONING
%  Nose gear load share must be 8-15% of total weight.
%  Main gear must be aft of most forward CoM to avoid tipping nose-up.

fprintf('=========================================================\n');
fprintf('  SECTION 3: GEAR PLACEMENT - LONGITUDINAL\n');
fprintf('=========================================================\n\n');

% --- Nose gear load share constraint ---
% Taking moments about MLG position:
% NLG load share = (x_MLG - x_CoM) / (x_MLG - x_NLG)
% Rearranging: x_MLG = x_CoM + NLG_frac * (x_MLG - x_NLG)
%
% Standard requirements:
%   NLG load share >= 8%  (steering effectiveness)
%   NLG load share <= 15% (NLG structural limit)

NLG_share_min   = 0.08;   % [-] Minimum NLG load share
NLG_share_max   = 0.15;   % [-] Maximum NLG load share
NLG_share_target = 0.10;  % [-] Target NLG load share

% NLG is typically at the nose, near the cockpit
x_NLG           = 4.5;   % [m] NLG position from nose

% From moment equation about NLG:
% Sum moments about NLG = 0:
% W_total * (x_CoM - x_NLG) = W_MLG * (x_MLG - x_NLG)
% x_MLG = x_NLG + (x_CoM - x_NLG) / MLG_load_fraction

% Calculate for forward, nominal, and aft CoM positions
x_CoM_cases     = [x_CoM_fwd, x_CoM_nom, x_CoM_aft];
CoM_case_names  = {'Forward CoM', 'Nominal CoM', 'Aft CoM'};

fprintf('Longitudinal Placement - MLG position for target NLG share:\n\n');
fprintf('  %-15s | x_CoM [m] | x_MLG_req [m] | NLG share [%%]\n', 'CoM Case');
fprintf('  %s\n', repmat('-',1,60));

x_MLG_results = zeros(1,3);
for i = 1:3
    xc = x_CoM_cases(i);
    % Moment balance: x_MLG minimises while keeping NLG share in range
    % Using target NLG share
    x_MLG_req = x_NLG + (xc - x_NLG) / (1 - NLG_share_target);
    x_MLG_results(i) = x_MLG_req;

    % Actual NLG share at this MLG position
    NLG_actual = (x_MLG_req - xc) / (x_MLG_req - x_NLG);

    fprintf('  %-15s | %9.2f | %13.2f | %12.1f\n', ...
        CoM_case_names{i}, xc, x_MLG_req, NLG_actual*100);
end

% Design MLG position = most aft required (worst case = aft CoM)
x_MLG = max(x_MLG_results);

fprintf('\n  Selected MLG position   : %.2f m from nose\n', x_MLG);
fprintf('  NLG position            : %.2f m from nose\n\n', x_NLG);

% --- Verify NLG load shares across CoM range ---
fprintf('NLG Load Share Verification:\n');
fprintf('  %-15s | NLG Share [%%] | Status\n', 'CoM Case');
fprintf('  %s\n', repmat('-',1,45));
for i = 1:3
    xc = x_CoM_cases(i);
    NLG_share = (x_MLG - xc) / (x_MLG - x_NLG);
    if NLG_share >= NLG_share_min && NLG_share <= NLG_share_max
        status = 'PASS';
    else
        status = 'FAIL - adjust MLG/NLG position';
    end
    fprintf('  %-15s | %12.1f | %s\n', CoM_case_names{i}, NLG_share*100, status);
end
fprintf('\n');

%  SECTION 4: GEAR PLACEMENT - LATERAL POSITIONING
%  Turnover angle must be < 63 degrees (standard stability requirement).
%  Main gear lateral span must be < 14m (ICAO Code E taxi limit).

fprintf('=========================================================\n');
fprintf('  SECTION 4: GEAR PLACEMENT - LATERAL (TURNOVER ANGLE)\n');
fprintf('=========================================================\n\n');

% Turnover angle is measured from the main gear contact point to the CoM
% in the lateral direction. Must be < 63 degrees.
% tan(turnover_angle) = h_CoM / (lateral_gear_track / 2)

% Aircraft CoM height above ground
% Estimated from fuselage geometry: bottom of fuselage + fuselage radius + CoM offset
h_fus_bottom    = tyre_diameter + 0.1;   % [m] clearance + tyre height approx
fus_radius      = 3.2;                   % [m] fuselage radius (B747-8F class)
h_CoM           = h_fus_bottom + fus_radius * 0.6;  % [m] CoM height above ground

% Turnover angle limit
turnover_limit  = 63.0;   % [deg]

% Required minimum gear half-track from turnover constraint:
% tan(63) = h_CoM / half_track => half_track = h_CoM / tan(63 deg)
half_track_min  = h_CoM / tand(turnover_limit);
track_min       = 2 * half_track_min;

% Apply ICAO Code E maximum span constraint
track_max       = max_gear_span_m;        % [m] = 14m for ICAO E

% Select gear track (between min and ICAO max)
% Add margin above minimum
y_MLG           = max(half_track_min * 1.15, 5.0);   % [m] MLG half-track from centreline
track_actual    = 2 * y_MLG;

fprintf('CoM height above ground    : %.2f m\n', h_CoM);
fprintf('Minimum gear track         : %.2f m  (turnover < %.0f deg)\n', ...
    track_min, turnover_limit);
fprintf('Maximum gear track         : %.2f m  (ICAO Code E)\n', track_max);
fprintf('Selected gear half-track   : %.2f m\n', y_MLG);
fprintf('Selected gear track        : %.2f m\n\n', track_actual);

% Verify turnover angle
turnover_angle  = atand(h_CoM / y_MLG);
fprintf('Turnover angle check:\n');
fprintf('  Actual turnover angle    : %.1f deg  ', turnover_angle);
if turnover_angle < turnover_limit
    fprintf('[PASS - below %.0f deg limit]\n', turnover_limit);
else
    fprintf('[FAIL - exceeds %.0f deg limit]\n', turnover_limit);
end

% ICAO code check
fprintf('  Gear track               : %.2f m  ', track_actual);
if track_actual <= track_max
    fprintf('[PASS - within %.0f m ICAO E limit]\n\n', track_max);
else
    fprintf('[FAIL - exceeds %.0f m ICAO E limit]\n\n', track_max);
end

% --- Bogie arrangement (4 bogies, 2 per side) ---
% Typical B747 style: 2 MLG struts per side, staggered longitudinally
% Inner bogie and outer bogie positions
y_MLG_inner     = y_MLG * 0.70;   % [m] Inner bogie half-track
y_MLG_outer     = y_MLG;          % [m] Outer bogie half-track

fprintf('Bogie Positions (symmetric about centreline):\n');
fprintf('  Inner bogie (x2)         : +/- %.2f m from centreline\n', y_MLG_inner);
fprintf('  Outer bogie (x2)         : +/- %.2f m from centreline\n\n', y_MLG_outer);

%% =========================================================================
%  SECTION 5: STRUT LENGTH - GEOMETRY
%   (a) Engine ground clearance >= 0.46 m
%   (b) Tail strike clearance at rotation angle

fprintf('=========================================================\n');
fprintf('  SECTION 5: STRUT LENGTH - GEOMETRIC REQUIREMENTS\n');
fprintf('=========================================================\n\n');

% --- (a) Engine clearance requirement ---
% Engine centreline is mounted below wing
% At compressed strut length L_s, aircraft height at wing = L_s + tyre_radius
% Engine bottom = wing height - engine_radius
% Clearance = engine bottom height above ground

tyre_radius     = tyre_diameter / 2;     % [m]
engine_radius   = engine_diameter / 2;   % [m]

% Wing height above ground = strut_compressed + tyre_radius
% Engine bottom clearance = wing_height - engine_radius - engine_pylon_drop
engine_pylon_drop = 0.3;   % [m] Engine hangs below wing by pylon

% Required strut compressed length from engine clearance:
% L_s + tyre_radius - engine_radius - engine_pylon_drop >= engine_clearance
% L_s >= engine_clearance + engine_radius + engine_pylon_drop - tyre_radius
L_s_engine = engine_clearance + engine_radius + engine_pylon_drop - tyre_radius;

fprintf('Engine Clearance Requirement:\n');
fprintf('  Engine diameter          : %.2f m\n', engine_diameter);
fprintf('  Required ground clearance: %.3f m\n', engine_clearance);
fprintf('  Minimum strut length     : %.3f m  (engine constraint)\n\n', L_s_engine);

% --- (b) Tail strike clearance ---
% At rotation, aircraft pitches up by tail_strike_angle degrees
% The tail contact point must clear the ground
% Geometry: clearance at tail = L_s*cos(theta) + x_dist*sin(theta) - h_tail
theta_rad       = deg2rad(tail_strike_angle);
x_dist_to_tail  = x_tail_contact - x_MLG;   % [m] horizontal dist from MLG to tail contact

% Height of tail contact point above ground during rotation:
% h = L_s*cos(theta) + x_dist*sin(theta) + tyre_radius - h_tail_contact
% For clearance >= 0: L_s >= (0 - x_dist*sin(theta) - tyre_radius + h_tail_contact) / cos(theta)
% We want h_clearance = 0.3 m minimum
min_tail_clearance = 0.3;  % [m]

L_s_tail = (min_tail_clearance - x_dist_to_tail*sin(theta_rad) ...
           - tyre_radius + h_tail_contact) / cos(theta_rad);

fprintf('Tail Strike Clearance Requirement:\n');
fprintf('  Tail strike angle        : %.1f deg\n', tail_strike_angle);
fprintf('  Distance MLG to tail     : %.2f m\n', x_dist_to_tail);
fprintf('  Minimum strut length     : %.3f m  (tail strike constraint)\n\n', L_s_tail);

% --- Select compressed strut length ---
L_s_compressed = max([L_s_engine, L_s_tail, 1.2]);  % minimum 1.2m practical
L_s_compressed = ceil(L_s_compressed * 10) / 10;    % round up to nearest 0.1m

fprintf('Selected compressed strut length: %.2f m\n\n', L_s_compressed);

% Extended strut length (strut extends by stroke during ground contact)
% Will be determined in Section 6 (shock absorber sizing)

%% =========================================================================
%  SECTION 6: SHOCK ABSORBER SIZING (Class II.5)
%  Determines stroke length, piston diameter, and landing gear mass.
%  Based on energy method: kinetic energy of sink rate absorbed by
%  shock absorber and tyre compression.
% =========================================================================

fprintf('=========================================================\n');
fprintf('  SECTION 6: SHOCK ABSORBER SIZING (Class II.5)\n');
fprintf('=========================================================\n\n');

% --- 6.1 Energy to be absorbed ---
% Landing mass (critical case = MLM)
% Kinetic energy from sink rate: E = 0.5 * m * V_sink^2
% This must be absorbed by the gear (shock absorber + tyre)

E_total_J = 0.5 * MLM_kg * V_sink^2;   % [J] Total kinetic energy at sink rate

% Energy absorbed per MLG strut (4 struts share the load)
E_per_strut_J = E_total_J / N_MLG_struts;

fprintf('6.1 Energy Absorption:\n');
fprintf('  Landing mass (MLM)       : %.1f tonnes\n', MLM_kg/1000);
fprintf('  Sink rate                : %.2f m/s\n', V_sink);
fprintf('  Total kinetic energy     : %.2f kJ\n', E_total_J/1000);
fprintf('  Energy per MLG strut     : %.2f kJ\n\n', E_per_strut_J/1000);

% --- 6.2 Stroke Length ---
% Energy balance per strut:
% E_strut = lambda * W_strut * (eta_shock * S_stroke + eta_tyre * d_tyre)
%
% Where:
%   lambda      = landing reaction factor
%   W_strut     = static load per strut = MLM*g * MLG_frac / N_struts
%   S_stroke    = shock absorber stroke [m]
%   d_tyre      = tyre deflection = 0.473 * tyre_radius (empirical)
%   eta_shock   = shock absorber efficiency
%   eta_tyre    = tyre efficiency

W_strut_N = MLM_kg * g * MLG_load_fraction / N_MLG_struts;  % [N]
d_tyre    = 0.473 * tyre_radius;                             % [m] tyre deflection

% Rearranging for stroke:
% S_stroke = (E_strut / (lambda * W_strut) - eta_tyre * d_tyre) / eta_shock
S_stroke = (E_per_strut_J / (lambda * W_strut_N) - eta_tyre * d_tyre) / eta_shock;

% Add margin (10%) and round up
S_stroke = S_stroke * 1.10;
S_stroke = ceil(S_stroke * 1000) / 1000;  % round up to nearest mm

fprintf('6.2 Shock Absorber Stroke:\n');
fprintf('  Static load per strut    : %.2f kN\n', W_strut_N/1e3);
fprintf('  Tyre deflection          : %.4f m\n', d_tyre);
fprintf('  Reaction factor lambda   : %.2f\n',   lambda);
fprintf('  Shock absorber efficiency: %.2f\n',   eta_shock);
fprintf('  Tyre efficiency          : %.2f\n',   eta_tyre);
fprintf('  Required stroke length   : %.4f m  (%.1f mm)\n\n', ...
    S_stroke, S_stroke*1000);

% --- 6.3 Extended strut length ---
L_s_extended = L_s_compressed + S_stroke;
fprintf('Strut Lengths:\n');
fprintf('  Compressed length        : %.3f m\n', L_s_compressed);
fprintf('  Stroke length            : %.4f m  (%.1f mm)\n', S_stroke, S_stroke*1000);
fprintf('  Extended length          : %.3f m\n\n', L_s_extended);

% --- 6.4 Piston Diameter ---
% Maximum hydraulic load = lambda * W_strut (at maximum compression)
% Hydraulic pressure in shock absorber (typical nitrogen/oil oleo):
P_hydraulic = 20.0e6;   % [Pa] Hydraulic working pressure (20 MPa typical)

F_max_N = lambda * W_strut_N;   % [N] Maximum axial force on piston

% Piston area from pressure: A = F / P
A_piston  = F_max_N / P_hydraulic;   % [m2]
d_piston  = 2 * sqrt(A_piston / pi); % [m] piston diameter

% Add wall thickness for structural sizing
t_wall    = d_piston * 0.15;         % [m] wall thickness ~15% of diameter
d_outer   = d_piston + 2 * t_wall;   % [m] outer cylinder diameter

fprintf('6.4 Piston and Cylinder Sizing:\n');
fprintf('  Max axial force          : %.2f kN\n', F_max_N/1e3);
fprintf('  Hydraulic pressure       : %.1f MPa\n', P_hydraulic/1e6);
fprintf('  Piston area              : %.6f m2\n',  A_piston);
fprintf('  Piston diameter          : %.4f m  (%.1f mm)\n', d_piston, d_piston*1000);
fprintf('  Wall thickness           : %.4f m  (%.1f mm)\n', t_wall, t_wall*1000);
fprintf('  Outer cylinder diameter  : %.4f m  (%.1f mm)\n\n', d_outer, d_outer*1000);

%% =========================================================================
%  SECTION 7: LANDING GEAR MASS ESTIMATION
%  Class I/II:  Empirical fraction of MTOM
%  Class II.5:  Physics-based from strut geometry and material
% =========================================================================

fprintf('=========================================================\n');
fprintf('  SECTION 7: LANDING GEAR MASS ESTIMATION\n');
fprintf('=========================================================\n\n');

% --- 7.1 Class I Mass Estimate (Raymer empirical fractions) ---
MLG_mass_I = MLG_mass_fraction * MTOM_kg;    % [kg] Total main gear
NLG_mass_I = NLG_mass_fraction * MTOM_kg;    % [kg] Nose gear
LG_total_I = MLG_mass_I + NLG_mass_I;        % [kg] Total landing gear

fprintf('7.1 Class I Mass Estimate (empirical fractions):\n');
fprintf('  MLG mass fraction        : %.3f\n', MLG_mass_fraction);
fprintf('  NLG mass fraction        : %.3f\n', NLG_mass_fraction);
fprintf('  MLG mass (total)         : %.0f kg\n', MLG_mass_I);
fprintf('  NLG mass                 : %.0f kg\n', NLG_mass_I);
fprintf('  Total LG mass            : %.0f kg  (%.2f%% MTOM)\n\n', ...
    LG_total_I, 100*LG_total_I/MTOM_kg);

% --- 7.2 Class II Mass Estimate (Torenbeek / Raymer semi-empirical) ---
% Raymer Eq 15.29 for transport aircraft:
% W_MLG = 0.0106 * Kw * W_l^0.888 * L^0.25 * N_l^0.4 * (W_stall)^(-0.321)
%         * N_mw^(-0.5) * W_l^0.1 * V_stall
%
% Simplified Torenbeek for main gear mass [kg]:
% M_MLG = 0.0117 * (MLM/1000)^0.95 * (L_s * 100)^0.43 * N_MLG_wheels^0.525

MLM_tonnes = MLM_kg / 1000;
M_MLG_II   = 0.0117 * MLM_tonnes^0.95 * (L_s_compressed*100)^0.43 ...
             * N_MLG_wheels^0.525;    % Torenbeek semi-empirical [kg]

% Nose gear: typically 20-25% of main gear mass by Torenbeek
M_NLG_II   = 0.22 * M_MLG_II;
LG_total_II = M_MLG_II + M_NLG_II;

fprintf('7.2 Class II Mass Estimate (Torenbeek semi-empirical):\n');
fprintf('  MLG mass (total)         : %.0f kg\n', M_MLG_II);
fprintf('  NLG mass                 : %.0f kg\n', M_NLG_II);
fprintf('  Total LG mass            : %.0f kg  (%.2f%% MTOM)\n\n', ...
    LG_total_II, 100*LG_total_II/MTOM_kg);

% --- 7.3 Class II.5 Physics-Based Strut Mass ---
% Estimate cylinder (outer tube) mass from geometry and material

% Outer cylinder: length = extended stroke + overlap
L_cylinder  = L_s_extended * 1.3;   % [m] cylinder with overlap allowance
A_wall      = pi/4 * (d_outer^2 - d_piston^2);  % [m2] annular cross-section area
V_cylinder  = A_wall * L_cylinder;              % [m3] volume of steel
m_cylinder  = rho_steel * V_cylinder;           % [kg] cylinder mass

% Add piston rod mass (solid rod, diameter = d_piston * 0.6)
d_rod       = d_piston * 0.6;                   % [m]
L_rod       = L_s_extended * 1.1;               % [m]
V_rod       = pi/4 * d_rod^2 * L_rod;
m_rod       = rho_steel * V_rod;

% Axle + wheels + brakes mass estimate (per bogie, 6 wheels)
% Typical 6-wheel bogie assembly: ~400 kg per bogie (axle+wheels+brakes)
m_bogie_assembly = 2200;   % [kg] per 6-wheel bogie (tyre + wheel + brake + axle)
m_bogies_total   = N_MLG_struts * m_bogie_assembly;

% Total strut mass (cylinder + rod + fittings factor 1.3)
m_strut_single  = (m_cylinder + m_rod) * 1.3;    % [kg] per strut with fittings
m_MLG_struts    = N_MLG_struts * m_strut_single;  % [kg] all MLG struts
M_MLG_II5       = m_MLG_struts + m_bogies_total;  % [kg] total MLG

% NLG: 2 wheels, smaller strut - estimate as 18% of MLG
M_NLG_II5       = 0.18 * M_MLG_II5;
LG_total_II5    = M_MLG_II5 + M_NLG_II5;

fprintf('7.3 Class II.5 Physics-Based Mass Estimate:\n');
fprintf('  Cylinder outer diameter  : %.4f m\n', d_outer);
fprintf('  Cylinder length          : %.3f m\n', L_cylinder);
fprintf('  Cylinder mass (per strut): %.1f kg\n', m_cylinder);
fprintf('  Piston rod mass (per)    : %.1f kg\n', m_rod);
fprintf('  Strut mass with fittings : %.1f kg (per strut)\n', m_strut_single);
fprintf('  Bogie assembly (per)     : %.0f kg\n', m_bogie_assembly);
fprintf('  MLG total mass           : %.0f kg\n', M_MLG_II5);
fprintf('  NLG mass                 : %.0f kg\n', M_NLG_II5);
fprintf('  Total LG mass            : %.0f kg  (%.2f%% MTOM)\n\n', ...
    LG_total_II5, 100*LG_total_II5/MTOM_kg);

%% =========================================================================
%  SECTION 8: SENSITIVITY STUDY - LG Mass vs MTOM
% =========================================================================

fprintf('=========================================================\n');
fprintf('  SECTION 8: SENSITIVITY STUDY - LG Mass vs MTOM\n');
fprintf('=========================================================\n\n');

MTOM_range    = linspace(150000, 550000, 50);   % [kg]
MLG_mass_s_I  = MLG_mass_fraction * MTOM_range;
NLG_mass_s_I  = NLG_mass_fraction * MTOM_range;
LG_total_s_I  = MLG_mass_s_I + NLG_mass_s_I;

% Torenbeek Class II vs MTOM (using fixed strut length)
MLM_range     = MTOM_range * (MLM_kg/MTOM_kg);   % scale MLM with MTOM
MLG_mass_s_II = 0.0117 * (MLM_range/1000).^0.95 ...
              * (L_s_compressed*100)^0.43 * N_MLG_wheels^0.525;
NLG_mass_s_II = 0.22 * MLG_mass_s_II;
LG_total_s_II = MLG_mass_s_II + NLG_mass_s_II;

fprintf('MTOM [t] | Class I LG [kg] | Class II LG [kg]\n');
fprintf('---------|-----------------|------------------\n');
checkpoints = [150,250,350,450,550];
for cp = checkpoints
    [~,idx] = min(abs(MTOM_range/1000 - cp));
    fprintf('  %4d   |     %8.0f    |     %8.0f\n', ...
        cp, LG_total_s_I(idx), LG_total_s_II(idx));
end
fprintf('\n');

%% =========================================================================
%  SECTION 9: SENSITIVITY STUDY - Stroke Length vs Sink Rate
% =========================================================================

fprintf('=========================================================\n');
fprintf('  SECTION 9: SENSITIVITY STUDY - Stroke vs Sink Rate\n');
fprintf('=========================================================\n\n');

V_sink_range   = linspace(1.0, 4.5, 50);
stroke_range   = zeros(1, length(V_sink_range));

for i = 1:length(V_sink_range)
    E_i        = 0.5 * MLM_kg * V_sink_range(i)^2;
    E_strut_i  = E_i / N_MLG_struts;
    S_i = (E_strut_i / (lambda * W_strut_N) - eta_tyre * d_tyre) / eta_shock;
    stroke_range(i) = max(S_i * 1.10, 0.05);  % minimum 50mm
end

fprintf('Sink Rate [m/s] | Stroke [mm]\n');
fprintf('----------------|------------\n');
V_check = [1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5];
for vc = V_check
    [~,idx] = min(abs(V_sink_range - vc));
    fprintf('      %.1f        |   %6.1f\n', vc, stroke_range(idx)*1000);
end
fprintf('\n');

%% =========================================================================
%  SECTION 10: FIGURES
% =========================================================================

% --- Figure 1: Landing Gear Layout (top view schematic) ---
figure('Name','Figure 1: Landing Gear Layout - Top View', ...
       'NumberTitle','off','Position',[50 50 800 500]);

hold on; axis equal;

% Fuselage centreline
plot([0 L_fus],[0 0],'k-','LineWidth',3);
plot([0 L_fus],[fus_radius fus_radius],'b--','LineWidth',1);
plot([0 L_fus],[-fus_radius -fus_radius],'b--','LineWidth',1);

% NLG
plot(x_NLG, 0,   'gs', 'MarkerSize', 14, 'MarkerFaceColor','g');
plot(x_NLG, 0.3, 'gs', 'MarkerSize', 14, 'MarkerFaceColor','g');

% MLG inner bogies (x2 per side)
x_MLG_fwd  = x_MLG - 1.5;   % forward bogie
x_MLG_aft  = x_MLG + 1.5;   % aft bogie

sides = [y_MLG_inner, -y_MLG_inner];
for s = sides
    plot(x_MLG_fwd, s, 'rs', 'MarkerSize', 16, 'MarkerFaceColor','r');
    plot(x_MLG_aft, s, 'rs', 'MarkerSize', 16, 'MarkerFaceColor','r');
end

% MLG outer bogies
sides_outer = [y_MLG_outer, -y_MLG_outer];
for s = sides_outer
    plot(x_MLG_fwd, s, 'ms', 'MarkerSize', 16, 'MarkerFaceColor','m');
    plot(x_MLG_aft, s, 'ms', 'MarkerSize', 16, 'MarkerFaceColor','m');
end

% CoM range indicator
plot([x_CoM_fwd x_CoM_aft],[0 0],'c-','LineWidth',5);
plot(x_CoM_nom, 0, 'c^', 'MarkerSize',12, 'MarkerFaceColor','c');

% Labels
text(x_NLG+0.5, 1.5, 'NLG (2 wheels)', 'FontSize', 9, 'Color','g');
text(x_MLG+0.5, y_MLG_inner+1, 'Inner Bogies (6whl each)', 'FontSize', 9, 'Color','r');
text(x_MLG+0.5, y_MLG_outer+1, 'Outer Bogies (6whl each)', 'FontSize', 9, 'Color','m');
text(x_CoM_nom+0.5, -1.5, 'CoM Range', 'FontSize', 9, 'Color','c');

xlabel('Distance from Nose [m]', 'FontSize', 11);
ylabel('Lateral Position [m]',   'FontSize', 11);
title(sprintf('Landing Gear Layout - Top View\nNLG at x=%.1fm, MLG at x=%.1fm', ...
    x_NLG, x_MLG), 'FontSize', 12);
legend({'Fuselage CL','Fus Side','','NLG','','Inner MLG','','Outer MLG','CoM Range'}, ...
    'Location','northeast','FontSize',9);
xlim([-2 L_fus+2]); ylim([-12 12]);
grid on; hold off;

% --- Figure 2: LG Mass vs MTOM ---
figure('Name','Figure 2: LG Mass vs MTOM','NumberTitle','off', ...
       'Position',[880 50 700 450]);

plot(MTOM_range/1000, LG_total_s_I/1000,  'b-',  'LineWidth', 2, ...
     'DisplayName','Class I (empirical)');
hold on;
plot(MTOM_range/1000, LG_total_s_II/1000, 'r--', 'LineWidth', 2, ...
     'DisplayName','Class II (Torenbeek)');
plot(MTOM_kg/1000, LG_total_I/1000, 'bo', 'MarkerSize',12, ...
     'MarkerFaceColor','b', 'DisplayName','Design Pt Class I');
plot(MTOM_kg/1000, LG_total_II/1000,'rs', 'MarkerSize',12, ...
     'MarkerFaceColor','r', 'DisplayName','Design Pt Class II');

xlabel('MTOM [tonnes]',              'FontSize', 11);
ylabel('Total Landing Gear Mass [tonnes]', 'FontSize', 11);
title('Landing Gear Mass vs MTOM',   'FontSize', 12);
legend('Location','northwest', 'FontSize', 10);
grid on; hold off;

% --- Figure 3: Stroke Length vs Sink Rate ---
figure('Name','Figure 3: Stroke vs Sink Rate','NumberTitle','off', ...
       'Position',[50 570 700 400]);

plot(V_sink_range, stroke_range*1000, 'k-', 'LineWidth', 2);
hold on;
plot(V_sink, S_stroke*1000, 'ro', 'MarkerSize', 12, 'MarkerFaceColor','r', ...
     'DisplayName', sprintf('Design point: %.1f m/s => %.0f mm', V_sink, S_stroke*1000));
xline(3.0, 'r--', 'CS-25 limit (3.0 m/s)', 'LineWidth', 1.5, 'FontSize', 10);

xlabel('Sink Rate [m/s]',           'FontSize', 11);
ylabel('Shock Absorber Stroke [mm]','FontSize', 11);
title('Shock Absorber Stroke vs Design Sink Rate', 'FontSize', 12);
legend('Stroke curve', 'Design point', 'CS-25 limit', ...
       'Location','northwest', 'FontSize', 10);
grid on; hold off;

% --- Figure 4: Mass Comparison Bar Chart ---
figure('Name','Figure 4: LG Mass Breakdown','NumberTitle','off', ...
       'Position',[780 570 600 420]);

categories  = {'Class I', 'Class II', 'Class II.5'};
MLG_vals    = [MLG_mass_I, M_MLG_II, M_MLG_II5] / 1000;
NLG_vals    = [NLG_mass_I, M_NLG_II, M_NLG_II5] / 1000;

b = bar([MLG_vals; NLG_vals]', 'stacked');
b(1).FaceColor = [0.2 0.4 0.8];
b(2).FaceColor = [0.8 0.3 0.2];
set(gca,'XTickLabel', categories, 'FontSize', 11);
ylabel('Landing Gear Mass [tonnes]', 'FontSize', 11);
title('Landing Gear Mass: Class I vs II vs II.5', 'FontSize', 12);
legend({'Main Landing Gear','Nose Landing Gear'}, 'Location','northeast', 'FontSize', 10);
grid on;

% Add value labels on bars
for i = 1:3
    total = MLG_vals(i) + NLG_vals(i);
    text(i, total + 0.2, sprintf('%.1f t', total), ...
        'HorizontalAlignment','center', 'FontSize', 10, 'FontWeight','bold');
end

%% =========================================================================
%  SECTION 11: FINAL RESULTS SUMMARY
% =========================================================================

fprintf('\n');
fprintf('=========================================================\n');
fprintf('  FINAL RESULTS SUMMARY\n');
fprintf('=========================================================\n\n');

fprintf('CONFIGURATION:\n');
fprintf('  Main gear     : %d struts, %d wheels/strut, %d wheels total\n', ...
    N_MLG_struts, N_wheels_bogie, N_MLG_wheels);
fprintf('  Nose gear     : 1 strut,  2 wheels\n\n');

fprintf('PLACEMENT:\n');
fprintf('  NLG position  : x = %.2f m from nose\n', x_NLG);
fprintf('  MLG position  : x = %.2f m from nose\n', x_MLG);
fprintf('  MLG half-track: y = %.2f m (track = %.2f m)\n', y_MLG, track_actual);
fprintf('  Turnover angle: %.1f deg  (limit = %.0f deg)\n\n', ...
    turnover_angle, turnover_limit);

fprintf('STRUT GEOMETRY:\n');
fprintf('  Compressed length : %.3f m\n', L_s_compressed);
fprintf('  Stroke length     : %.4f m  (%.1f mm)\n', S_stroke, S_stroke*1000);
fprintf('  Extended length   : %.3f m\n', L_s_extended);
fprintf('  Piston diameter   : %.4f m  (%.1f mm)\n', d_piston, d_piston*1000);
fprintf('  Outer cylinder    : %.4f m  (%.1f mm)\n\n', d_outer, d_outer*1000);

fprintf('MASS ESTIMATES:\n');
fprintf('  %-12s  %10s  %10s  %10s\n', ...
    'Component', 'Class I', 'Class II', 'Class II.5');
fprintf('  %s\n', repmat('-',1,50));
fprintf('  %-12s  %10.0f  %10.0f  %10.0f  kg\n', ...
    'MLG total', MLG_mass_I, M_MLG_II, M_MLG_II5);
fprintf('  %-12s  %10.0f  %10.0f  %10.0f  kg\n', ...
    'NLG', NLG_mass_I, M_NLG_II, M_NLG_II5);
fprintf('  %s\n', repmat('-',1,50));
fprintf('  %-12s  %10.0f  %10.0f  %10.0f  kg\n', ...
    'TOTAL LG', LG_total_I, LG_total_II, LG_total_II5);
fprintf('  %-12s  %10.2f  %10.2f  %10.2f  %% MTOM\n', ...
    '% of MTOM', ...
    100*LG_total_I/MTOM_kg, ...
    100*LG_total_II/MTOM_kg, ...
    100*LG_total_II5/MTOM_kg);

fprintf('\n');
fprintf('TYRE CHECK:\n');
fprintf('  Load per MLG tyre : %.0f kg  ', W_per_MLG_wheel_kg);
if W_per_MLG_wheel_kg <= 40000
    fprintf('[PASS]\n');
else
    fprintf('[CHECK FLOTATION]\n');
end
fprintf('  Turnover angle    : %.1f deg  ', turnover_angle);
if turnover_angle < 63
    fprintf('[PASS]\n');
else
    fprintf('[FAIL]\n');
end
fprintf('  Gear track        : %.2f m  ', track_actual);
if track_actual <= 14.0
    fprintf('[PASS - ICAO E]\n');
else
    fprintf('[EXCEEDS ICAO E]\n');
end

fprintf('\n');
fprintf('=========================================================\n');
fprintf('  Analysis complete. 4 figures generated.\n');
fprintf('=========================================================\n\n');