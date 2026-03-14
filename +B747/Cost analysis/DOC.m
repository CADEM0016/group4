%% =========================================================================
%  DOC_Standalone.m
%  Direct Operating Cost (DOC) Analysis - CADEM0016 Group Design Project
%  University of Bristol - MSc Aerospace Engineering
%
%  STANDALONE SCRIPT - No external files, functions, or toolboxes required.
%  Simply press RUN (F5) and all results will be printed to the console
%  and displayed as figures.
%
%  Based on:
%    - CADEM0016 GDP Specification 2025, Section 4
%    - Aircraft Economics Lecture Notes (Healy, Bristol 2026)
%    - Raymer, Aircraft Design: A Conceptual Approach, 6th ed., Ch.18
%
%  Author  : Group 3 - Project Manager / Economics Engineer
%  Date    : March 2026
% =========================================================================

clear; clc; close all;

fprintf('=========================================================\n');
fprintf('  CADEM0016 - Direct Operating Cost (DOC) Analysis\n');
fprintf('  University of Bristol - Group 3\n');
fprintf('=========================================================\n\n');

%% =========================================================================
%  SECTION 1: AIRCRAFT DESIGN PARAMETERS
%  These are the top-level aircraft parameters.
%  Change these values to match your current MDO design point.
% =========================================================================

% --- Mass parameters ---
MTOM_kg        = 348700;      % [kg]   Maximum Take-Off Mass
                              %        B777F reference = 348,700 kg (spec Table 6)
OEM_kg         = 145000;      % [kg]   Operational Empty Mass
                              %        B777F reference = 145,000 kg

% --- Performance parameters (needed for Class II cost model) ---
V_max_kmh      = 905;         % [km/h] Maximum cruise velocity
                              %        B777F ~ Mach 0.84 at 35,000 ft ~ 905 km/h
M_max          = 0.89;        % [-]    Maximum (dive) Mach number
T_max_kN       = 513;         % [kN]   Max thrust per engine (GE90-115B ~ 513 kN)
T3_K           = 1550;        % [K]    Turbine inlet temperature (approx GE90 class)
N_engines      = 2;           % [-]    Number of engines

% --- Airport / configuration ---
% Taxi span ICAO code. Your aircraft has a 72m flight span but folds
% to 65m taxi span => ICAO Code E (52-65m, parking $4000/day)
% Options: 'C' = $1000/day, 'D' = $2000/day, 'E' = $4000/day, 'F' = $6000/day
ICAO_code      = 'E';

% --- Fuel ---
% Options: 'kerosene' ($1.00/litre) or 'SAF' ($2.00/litre)
fuel_type      = 'kerosene';

fprintf('--- Aircraft Design Parameters ---\n');
fprintf('  MTOM                 : %.1f tonnes\n', MTOM_kg/1000);
fprintf('  OEM                  : %.1f tonnes\n', OEM_kg/1000);
fprintf('  Max velocity         : %.0f km/h\n',  V_max_kmh);
fprintf('  Number of engines    : %d\n',          N_engines);
fprintf('  Taxi ICAO code       : %s\n',          ICAO_code);
fprintf('  Fuel type            : %s\n\n',        fuel_type);

%% =========================================================================
%  SECTION 2: FLEET AND MISSION PARAMETERS
%  Based on the F1 2026 season (spec Table 3).
%  14 fly-away legs require air freight.
% =========================================================================

fleet_size      = 8;          % [-]   Number of aircraft in the fleet
                              %       8 B777F-equivalent aircraft needed
                              %       (spec Appendix B: 736t / 92t per aircraft)

N_landings      = 28;         % [-]   Landings per aircraft per season
                              %       14 outbound + 14 return legs

% Block fuel per aircraft per season
% Estimate: average leg distance ~8000 km, fuel burn ~5 kg/km for B777F class
% => 14 legs x 8000 km x 5 kg/km = 560,000 kg. Using 580,000 kg with reserves.
block_fuel_kg   = 580000;     % [kg]  per aircraft per season

% Flight hours per aircraft per season
% Estimate: 14 legs x ~10 hrs average = 140 hrs outbound + 140 return = ~280 hrs
flight_hours    = 280;        % [h]   per aircraft per season

% Parking days per aircraft per season
% 14 race venues x 4 days average parking = 56 days
parking_days    = 56;         % [days] per aircraft per season

% 5-year production quantity (for DAPCA IV Class II model)
% For a bespoke F1 fleet, production quantity = fleet size
N_production    = fleet_size; % [-]   assume all built within 5 years

% Physical constants
fuel_density    = 0.8;        % [kg/litre]  spec Section 3.6

fprintf('--- Fleet and Mission Parameters ---\n');
fprintf('  Fleet size           : %d aircraft\n', fleet_size);
fprintf('  Landings/aircraft/yr : %d\n',          N_landings);
fprintf('  Block fuel/aircraft  : %.0f tonnes\n', block_fuel_kg/1000);
fprintf('  Flight hours/aircraft: %.0f h\n',      flight_hours);
fprintf('  Parking days/aircraft: %d days\n\n',   parking_days);

%% =========================================================================
%  SECTION 3: CLASS I DOC CALCULATION
%  Uses the simplified formulae directly from the GDP Specification
%  Section 4. This is the Sprint 2 model.
% =========================================================================

fprintf('=========================================================\n');
fprintf('  CLASS I DOC  (Sprint 2 - Specification Formulae)\n');
fprintf('=========================================================\n\n');

% ----- 3.1 Crew Salaries (Spec Section 4.1) -----
% 4 crew per aircraft x $150,000/yr each = $600,000/aircraft/yr
crew_per_ac       = 4;
salary_per_crew   = 150000;                        % USD/yr
cost_crew_per_ac  = crew_per_ac * salary_per_crew; % USD/yr per aircraft
cost_crew_total   = fleet_size * cost_crew_per_ac; % USD/yr fleet total

fprintf('3.1 Crew Salaries\n');
fprintf('    %d crew x $%.0f/yr = $%.0f per aircraft\n', ...
    crew_per_ac, salary_per_crew, cost_crew_per_ac);
fprintf('    Fleet total : $%.0f /yr\n\n', cost_crew_total);

% ----- 3.2 Landing Fees (Spec Section 4.2) -----
% $25 per tonne of MTOM per landing
MTOM_tonnes         = MTOM_kg / 1000;
fee_per_landing     = 25 * MTOM_tonnes;           % USD per landing
cost_landing_per_ac = fee_per_landing * N_landings;
cost_landing_total  = fleet_size * cost_landing_per_ac;

fprintf('3.2 Landing Fees\n');
fprintf('    $25/tonne x %.1f t x %d landings = $%.0f per aircraft\n', ...
    MTOM_tonnes, N_landings, cost_landing_per_ac);
fprintf('    Fleet total : $%.0f /yr\n\n', cost_landing_total);

% ----- 3.3 Parking Fees (Spec Section 4.3) -----
% Daily rate by ICAO code (ground/taxi span)
switch upper(ICAO_code)
    case 'C';  daily_parking_fee = 1000;
    case 'D';  daily_parking_fee = 2000;
    case 'E';  daily_parking_fee = 4000;
    case 'F';  daily_parking_fee = 6000;
    otherwise; error('ICAO code must be C, D, E or F');
end

cost_parking_per_ac = daily_parking_fee * parking_days;
cost_parking_total  = fleet_size * cost_parking_per_ac;

fprintf('3.3 Parking Fees\n');
fprintf('    ICAO Code %s => $%.0f/day x %d days = $%.0f per aircraft\n', ...
    ICAO_code, daily_parking_fee, parking_days, cost_parking_per_ac);
fprintf('    Fleet total : $%.0f /yr\n\n', cost_parking_total);

% ----- 3.4 Fuel Costs (Spec Section 4.4) -----
% Kerosene: $1.00/litre,  SAF: $2.00/litre
% Fuel density: 0.8 kg/litre
switch lower(fuel_type)
    case 'kerosene';  fuel_price = 1.00;   % USD/litre
    case 'saf';       fuel_price = 2.00;
    otherwise;        error('fuel_type must be kerosene or SAF');
end

block_fuel_litres   = block_fuel_kg / fuel_density;
cost_fuel_per_ac    = block_fuel_litres * fuel_price;
cost_fuel_total     = fleet_size * cost_fuel_per_ac;

fprintf('3.4 Fuel Costs\n');
fprintf('    %.0f kg / %.1f kg/l = %.0f litres x $%.2f/l = $%.0f per aircraft\n', ...
    block_fuel_kg, fuel_density, block_fuel_litres, fuel_price, cost_fuel_per_ac);
fprintf('    Fleet total : $%.0f /yr\n\n', cost_fuel_total);

% ----- 3.5 Hull Value (Spec Eq.1) -----
% V_hull = 44,880 x MTOM^0.65   [USD, MTOM in kg]
V_hull = 44880 * (MTOM_kg ^ 0.65);

fprintf('3.5 Hull Value\n');
fprintf('    V_hull = 44880 x %.0f^0.65 = $%.2f M\n', ...
    MTOM_kg, V_hull/1e6);

% ----- 3.6 Maintenance Costs (Spec Eqs. 2 & 3) -----
% Fixed:    C_m_fixed = 0.03 x V_hull   [USD/yr]
% Variable: C_m_var   = 5e-6 x V_hull   [USD/flight hour]
C_m_fixed = 0.03 * V_hull;
C_m_var   = 5e-6 * V_hull;
cost_maint_per_ac  = C_m_fixed + C_m_var * flight_hours;
cost_maint_total   = fleet_size * cost_maint_per_ac;

fprintf('\n3.6 Maintenance Costs\n');
fprintf('    Fixed  : 0.03 x $%.2fM = $%.0f /yr\n',    V_hull/1e6, C_m_fixed);
fprintf('    Variable: 5e-6 x $%.2fM x %.0f FH = $%.0f /yr\n', ...
    V_hull/1e6, flight_hours, C_m_var*flight_hours);
fprintf('    Total per aircraft : $%.0f /yr\n', cost_maint_per_ac);
fprintf('    Fleet total        : $%.0f /yr\n\n', cost_maint_total);

% ----- 3.7 Insurance Costs (Spec Eq. 4) -----
% C_ins = 0.005 x V_hull = 224.4 x MTOM^0.65
C_ins = 0.005 * V_hull;
cost_ins_total = fleet_size * C_ins;

fprintf('3.7 Insurance Costs\n');
fprintf('    C_ins = 0.005 x $%.2fM = $%.0f per aircraft\n', V_hull/1e6, C_ins);
fprintf('    Fleet total : $%.0f /yr\n\n', cost_ins_total);

% ----- 3.8 Class I Totals -----
COC_I = cost_crew_total + cost_landing_total + cost_parking_total ...
      + cost_fuel_total + cost_maint_total + cost_ins_total;

% No depreciation/interest in Class I (initial cost not modelled yet)
DOC_I = COC_I;

fprintf('----------------------------------------------------------\n');
fprintf('CLASS I RESULTS (entire fleet per year):\n');
fprintf('  Crew salaries        : $%14.0f\n', cost_crew_total);
fprintf('  Landing fees         : $%14.0f\n', cost_landing_total);
fprintf('  Parking fees         : $%14.0f\n', cost_parking_total);
fprintf('  Fuel cost            : $%14.0f\n', cost_fuel_total);
fprintf('  Maintenance          : $%14.0f\n', cost_maint_total);
fprintf('  Insurance            : $%14.0f\n', cost_ins_total);
fprintf('  Depreciation         : $%14.0f  (not modelled in Class I)\n', 0);
fprintf('  Interest             : $%14.0f  (not modelled in Class I)\n', 0);
fprintf('----------------------------------------------------------\n');
fprintf('  TOTAL COC (fleet)    : $%14.0f /yr\n', COC_I);
fprintf('  TOTAL DOC (fleet)    : $%14.0f /yr\n', DOC_I);
fprintf('  DOC per aircraft     : $%14.0f /yr\n', DOC_I/fleet_size);
fprintf('  DOC per flight       : $%14.0f\n',     DOC_I/(fleet_size*N_landings));
fprintf('----------------------------------------------------------\n\n');

%% =========================================================================
%  SECTION 4: CLASS II DOC CALCULATION
%  Uses DAPCA IV method (Raymer Section 18) for initial cost estimate,
%  then adds depreciation and interest.
%  This is the Sprint 3 model.
% =========================================================================

fprintf('=========================================================\n');
fprintf('  CLASS II DOC  (Sprint 3 - DAPCA IV + Financial Costs)\n');
fprintf('=========================================================\n\n');

CPI_2012_to_2026 = 1.43;   % CPI inflation factor (per lecture notes)

% ----- 4.1 Labour Hours (Raymer Ch.18 DAPCA IV) -----
Me = OEM_kg;
V  = V_max_kmh;
N  = N_production;
Nft = 2;           % number of flight test aircraft

H_E = 5.18  * Me^0.777 * V^0.894 * N^0.163;   % Engineering hours
H_T = 7.22  * Me^0.777 * V^0.696 * N^0.263;   % Tooling hours
H_M = 10.5  * Me^0.82  * V^0.484 * N^0.641;   % Manufacturing hours
H_Q = 0.076 * H_M;                             % QC hours (cargo aircraft)

fprintf('4.1 Labour Hours (DAPCA IV)\n');
fprintf('    Engineering    H_E = %.2e hrs\n', H_E);
fprintf('    Tooling        H_T = %.2e hrs\n', H_T);
fprintf('    Manufacturing  H_M = %.2e hrs\n', H_M);
fprintf('    Quality Ctrl   H_Q = %.2e hrs\n\n', H_Q);

% ----- 4.2 Labour Cost -----
% Labour rates (2012 USD, Raymer Table 18.1)
R_E = 115;   % Engineering    USD/hr
R_T = 118;   % Tooling        USD/hr
R_M = 98;    % Manufacturing  USD/hr
R_Q = 108;   % Quality ctrl   USD/hr

% Material complexity factor (1.0 = aluminium, 1.1-1.8 = composites)
% Using 1.0 for aluminium baseline; adjust if significant CFRP content
eta_M = 1.0;

C_lab = (H_E*R_E + H_T*R_T + H_M*R_M + H_Q*R_Q) * eta_M;

fprintf('4.2 Labour Cost (2012 USD)\n');
fprintf('    C_lab = $%.2f M\n\n', C_lab/1e6);

% ----- 4.3 Development, Flight Test, Material, Engine Costs -----
C_D = 67.4  * Me^0.63  * V^1.3;                               % Development
C_F = 1947  * Me^0.325 * V^0.822 * Nft^1.21;                  % Flight test
C_m = 31.2  * Me^0.921 * V^0.621 * N^0.799;                   % Materials
C_E_single = 3112*(9.66*T_max_kN + 243.25*M_max + 1.74*T3_K - 2228); % Per engine
C_E_total  = C_E_single * N_engines;                           % All engines

fprintf('4.3 Other Programme Costs (2012 USD)\n');
fprintf('    Development     C_D = $%.2f M\n', C_D/1e6);
fprintf('    Flight test     C_F = $%.2f M\n', C_F/1e6);
fprintf('    Materials       C_m = $%.2f M\n', C_m/1e6);
fprintf('    Engine (each)   C_E = $%.2f M\n', C_E_single/1e6);
fprintf('    Engines (all)       = $%.2f M\n\n', C_E_total/1e6);

% ----- 4.4 Total Programme Cost -> Per Aircraft Cost -----
C_programme_2012 = C_lab + C_D + C_F + C_m + C_E_total;
C_programme_2026 = C_programme_2012 * CPI_2012_to_2026;
C_per_aircraft   = C_programme_2026 / N_production;   % USD per aircraft

% Airframe cost (less engines) for maintenance model
C_airframe = (C_programme_2026 - C_E_total * CPI_2012_to_2026) / N_production;

fprintf('4.4 Programme Cost\n');
fprintf('    Total (2012 USD)    = $%.2f M\n', C_programme_2012/1e6);
fprintf('    Total (2026 USD)    = $%.2f M  (x CPI %.2f)\n', ...
    C_programme_2026/1e6, CPI_2012_to_2026);
fprintf('    Per aircraft (2026) = $%.2f M\n\n', C_per_aircraft/1e6);

% ----- 4.5 Class II Maintenance (Raymer Eq 18.12) -----
% material cost [USD/FH] = 3.3*(Ca/1e6) + 14.2 + [58*(Ce/1e6) - 26.1]*Ne
% Ca = aircraft cost less engines, Ce = cost per engine
Ca = C_airframe;
Ce = C_E_single * CPI_2012_to_2026;   % per engine in 2026 USD

maint_II_per_FH  = (3.3*(Ca/1e6) + 14.2 + (58*(Ce/1e6) - 26.1)*N_engines) ...
                   * CPI_2012_to_2026;
cost_maint_II_per_ac = maint_II_per_FH * flight_hours;
cost_maint_II_total  = fleet_size * cost_maint_II_per_ac;

fprintf('4.5 Class II Maintenance (Raymer Eq 18.12)\n');
fprintf('    Maintenance rate = $%.2f /FH\n', maint_II_per_FH);
fprintf('    Per aircraft     = $%.0f /yr\n', cost_maint_II_per_ac);
fprintf('    Fleet total      = $%.0f /yr\n\n', cost_maint_II_total);

% ----- 4.6 Financial Costs (Depreciation + Interest) -----
% From Aircraft Economics lecture notes (Healy 2026):
%   Depreciation = Total_Investment / 14   [USD/yr]  (14 yr economic life)
%   Interest     = 0.05 x Total_Investment [USD/yr]
dep_per_ac  = C_per_aircraft / 14;
int_per_ac  = 0.05 * C_per_aircraft;
cost_dep_total = fleet_size * dep_per_ac;
cost_int_total = fleet_size * int_per_ac;

fprintf('4.6 Financial Costs\n');
fprintf('    Aircraft value (per ac)  = $%.2f M\n', C_per_aircraft/1e6);
fprintf('    Depreciation (14 yr life): $%.0f /yr per aircraft\n', dep_per_ac);
fprintf('    Interest (5%% of value)  : $%.0f /yr per aircraft\n', int_per_ac);
fprintf('    Dep fleet total          : $%.0f /yr\n', cost_dep_total);
fprintf('    Int fleet total          : $%.0f /yr\n\n', cost_int_total);

% ----- 4.7 Class II Insurance (unchanged from Class I) -----
cost_ins_II_total = fleet_size * C_ins;   % same hull value model

% ----- 4.8 Class II Totals -----
COC_II = cost_crew_total   + cost_landing_total + cost_parking_total ...
       + cost_fuel_total   + cost_maint_II_total + cost_ins_II_total;

DOC_II = COC_II + cost_dep_total + cost_int_total;

fprintf('----------------------------------------------------------\n');
fprintf('CLASS II RESULTS (entire fleet per year):\n');
fprintf('  Crew salaries        : $%14.0f\n', cost_crew_total);
fprintf('  Landing fees         : $%14.0f\n', cost_landing_total);
fprintf('  Parking fees         : $%14.0f\n', cost_parking_total);
fprintf('  Fuel cost            : $%14.0f\n', cost_fuel_total);
fprintf('  Maintenance (Raymer) : $%14.0f\n', cost_maint_II_total);
fprintf('  Insurance            : $%14.0f\n', cost_ins_II_total);
fprintf('  Depreciation         : $%14.0f\n', cost_dep_total);
fprintf('  Interest             : $%14.0f\n', cost_int_total);
fprintf('----------------------------------------------------------\n');
fprintf('  TOTAL COC (fleet)    : $%14.0f /yr\n', COC_II);
fprintf('  TOTAL DOC (fleet)    : $%14.0f /yr\n', DOC_II);
fprintf('  DOC per aircraft     : $%14.0f /yr\n', DOC_II/fleet_size);
fprintf('  DOC per flight       : $%14.0f\n',     DOC_II/(fleet_size*N_landings));
fprintf('----------------------------------------------------------\n\n');

%% =========================================================================
%  SECTION 5: SENSITIVITY STUDY 1 - DOC vs Fleet Size
%  Required for poster deliverable (sensitivity of DOC to hyperparameters)
% =========================================================================

fprintf('=========================================================\n');
fprintf('  SENSITIVITY STUDY 1: DOC vs Fleet Size\n');
fprintf('=========================================================\n\n');

fleet_range  = 2:2:20;
n_f          = length(fleet_range);

DOC_I_fleet_total  = zeros(1, n_f);
DOC_I_fleet_per_ac = zeros(1, n_f);
DOC_II_fleet_total  = zeros(1, n_f);
DOC_II_fleet_per_ac = zeros(1, n_f);

% Total season fuel is fixed regardless of fleet size
% (same total freight to move; more aircraft = each carries less)
total_season_fuel_kg = block_fuel_kg * fleet_size;

for i = 1:n_f
    fs  = fleet_range(i);
    bfk = total_season_fuel_kg / fs;   % fuel per aircraft scales with fleet

    % --- Class I ---
    c_crew    = fs * crew_per_ac * salary_per_crew;
    c_land    = fs * fee_per_landing * N_landings;
    c_park    = fs * daily_parking_fee * parking_days;
    c_fuel    = fs * (bfk/fuel_density) * fuel_price;
    c_maint   = fs * (C_m_fixed + C_m_var * flight_hours);
    c_ins     = fs * C_ins;
    DOC_I_fleet_total(i)  = c_crew+c_land+c_park+c_fuel+c_maint+c_ins;
    DOC_I_fleet_per_ac(i) = DOC_I_fleet_total(i) / fs;

    % --- Class II ---
    % N_production scales with fleet (each fleet size = unique programme)
    N_p = fs;
    C_p = (C_lab_scaled(Me,V,N_p,Nft,T_max_kN,M_max,T3_K,N_engines,eta_M) ...
           * CPI_2012_to_2026) / N_p;   % per aircraft cost

    dep   = fs * C_p / 14;
    intr  = fs * 0.05 * C_p;
    DOC_II_fleet_total(i)  = DOC_I_fleet_total(i) - fs*(C_m_fixed + C_m_var*flight_hours) ...
                             + cost_maint_II_total * (fs/fleet_size) ...
                             + dep + intr;
    DOC_II_fleet_per_ac(i) = DOC_II_fleet_total(i) / fs;
end

fprintf('Fleet Size | DOC Class I (M$/yr) | DOC Class II (M$/yr)\n');
fprintf('-----------|---------------------|---------------------\n');
for i = 1:n_f
    fprintf('    %3d    |      %8.2f       |      %8.2f\n', ...
        fleet_range(i), ...
        DOC_I_fleet_total(i)/1e6, ...
        DOC_II_fleet_total(i)/1e6);
end
fprintf('\n');

%% =========================================================================
%  SECTION 6: SENSITIVITY STUDY 2 - DOC vs Fuel Type (Kerosene vs SAF)
% =========================================================================

fprintf('=========================================================\n');
fprintf('  SENSITIVITY STUDY 2: Kerosene vs SAF\n');
fprintf('=========================================================\n\n');

fuel_prices_usd = [1.00, 2.00];
fuel_names      = {'Kerosene ($1.00/L)', 'SAF ($2.00/L)'};

for k = 1:2
    fp   = fuel_prices_usd(k);
    cf   = fleet_size * (block_fuel_litres) * fp;
    doc_k = cost_crew_total + cost_landing_total + cost_parking_total ...
          + cf + cost_maint_total + cost_ins_total;
    fprintf('  %s:\n', fuel_names{k});
    fprintf('    Fuel cost  : $%.2f M/yr\n', cf/1e6);
    fprintf('    Total DOC  : $%.2f M/yr\n\n', doc_k/1e6);
end

fuel_premium = fleet_size * block_fuel_litres * (2.00 - 1.00);
fprintf('  SAF premium over Kerosene: $%.2f M/yr  (+%.1f%%)\n\n', ...
    fuel_premium/1e6, ...
    100*fuel_premium/(fleet_size*block_fuel_litres*1.00 + ...
    cost_crew_total+cost_landing_total+cost_parking_total+cost_maint_total+cost_ins_total));

%% =========================================================================
%  SECTION 7: SENSITIVITY STUDY 3 - DOC vs MTOM
%  Shows how DOC changes as aircraft gets heavier/lighter
% =========================================================================

fprintf('=========================================================\n');
fprintf('  SENSITIVITY STUDY 3: DOC vs MTOM\n');
fprintf('=========================================================\n\n');

MTOM_range_kg  = linspace(100000, 500000, 50);
DOC_vs_MTOM    = zeros(1, length(MTOM_range_kg));

for i = 1:length(MTOM_range_kg)
    mt  = MTOM_range_kg(i);
    Vh  = 44880 * mt^0.65;
    cl  = fleet_size * 25 * (mt/1000) * N_landings;         % landing fees
    cm  = fleet_size * (0.03*Vh + 5e-6*Vh*flight_hours);    % maintenance
    ci  = fleet_size * 0.005 * Vh;                          % insurance
    DOC_vs_MTOM(i) = cost_crew_total + cl + cost_parking_total ...
                   + cost_fuel_total + cm + ci;
end

fprintf('  MTOM [t] | DOC Class I [M$/yr]\n');
fprintf('  ---------|--------------------\n');
checkpoints = [100,200,300,400,500];
for cp = checkpoints
    [~,idx] = min(abs(MTOM_range_kg/1000 - cp));
    fprintf('    %4d   |      %8.2f\n', cp, DOC_vs_MTOM(idx)/1e6);
end
fprintf('\n');

%% =========================================================================
%  SECTION 8: FIGURES
% =========================================================================

%--- Figure 1: DOC Breakdown Pie Chart (Class I) ---
figure('Name','Figure 1: Class I DOC Breakdown','NumberTitle','off', ...
       'Position',[100 100 700 500]);

values_I = [cost_crew_total, cost_landing_total, cost_parking_total, ...
            cost_fuel_total, cost_maint_total,   cost_ins_total];
labels_I = {'Crew Salaries', 'Landing Fees', 'Parking Fees', ...
            'Fuel Cost',     'Maintenance',  'Insurance'};

explode = [0 0 0 1 0 0];   % highlight fuel cost
p = pie(values_I, explode);
title(sprintf('Class I DOC Breakdown\nFleet of %d aircraft, %s, MTOM=%.0ft', ...
    fleet_size, fuel_type, MTOM_tonnes), 'FontSize', 13);
legend(labels_I, 'Location','bestoutside', 'FontSize', 10);

%--- Figure 2: DOC Breakdown Pie Chart (Class II) ---
figure('Name','Figure 2: Class II DOC Breakdown','NumberTitle','off', ...
       'Position',[820 100 700 500]);

values_II = [cost_crew_total, cost_landing_total, cost_parking_total, ...
             cost_fuel_total, cost_maint_II_total, cost_ins_II_total, ...
             cost_dep_total,  cost_int_total];
labels_II = {'Crew Salaries', 'Landing Fees', 'Parking Fees', ...
             'Fuel Cost',     'Maintenance',  'Insurance', ...
             'Depreciation',  'Interest'};

mask = values_II > 0;
pie(values_II(mask));
title(sprintf('Class II DOC Breakdown\nFleet of %d aircraft, %s, MTOM=%.0ft', ...
    fleet_size, fuel_type, MTOM_tonnes), 'FontSize', 13);
legend(labels_II(mask), 'Location','bestoutside', 'FontSize', 10);

%--- Figure 3: DOC vs Fleet Size ---
figure('Name','Figure 3: DOC vs Fleet Size','NumberTitle','off', ...
       'Position',[100 620 900 400]);

subplot(1,2,1);
plot(fleet_range, DOC_I_fleet_total/1e6,  'b-o', 'LineWidth', 2, ...
     'MarkerFaceColor','b', 'DisplayName','Class I');
hold on;
plot(fleet_range, DOC_II_fleet_total/1e6, 'r-s', 'LineWidth', 2, ...
     'MarkerFaceColor','r', 'DisplayName','Class II');
xlabel('Fleet Size (number of aircraft)', 'FontSize', 11);
ylabel('Total Fleet DOC [M USD/yr]',       'FontSize', 11);
title('Total Fleet DOC vs Fleet Size',     'FontSize', 12);
legend('Location','northwest', 'FontSize', 10);
grid on;

subplot(1,2,2);
plot(fleet_range, DOC_I_fleet_per_ac/1e6,  'b-o', 'LineWidth', 2, ...
     'MarkerFaceColor','b', 'DisplayName','Class I');
hold on;
plot(fleet_range, DOC_II_fleet_per_ac/1e6, 'r-s', 'LineWidth', 2, ...
     'MarkerFaceColor','r', 'DisplayName','Class II');
xlabel('Fleet Size (number of aircraft)', 'FontSize', 11);
ylabel('DOC per Aircraft [M USD/yr]',      'FontSize', 11);
title('Per-Aircraft DOC vs Fleet Size',    'FontSize', 12);
legend('Location','northeast', 'FontSize', 10);
grid on;

%--- Figure 4: DOC vs MTOM ---
figure('Name','Figure 4: DOC vs MTOM','NumberTitle','off', ...
       'Position',[820 620 600 400]);

plot(MTOM_range_kg/1000, DOC_vs_MTOM/1e6, 'k-', 'LineWidth', 2);
hold on;
plot(MTOM_tonnes, DOC_I/1e6, 'ro', 'MarkerSize', 12, ...
    'MarkerFaceColor','r', 'DisplayName', 'B777F Reference Point');
xlabel('MTOM [tonnes]',       'FontSize', 11);
ylabel('Total DOC [M USD/yr]','FontSize', 11);
title('Fleet DOC Sensitivity to MTOM','FontSize', 12);
legend({'DOC curve','Design Point (B777F ref)'}, ...
    'Location','northwest', 'FontSize', 10);
grid on;

%% =========================================================================
%  SECTION 9: FINAL SUMMARY TABLE
% =========================================================================

fprintf('\n');
fprintf('=========================================================\n');
fprintf('  FINAL SUMMARY\n');
fprintf('=========================================================\n');
fprintf('\n');
fprintf('  %-30s  %15s  %15s\n', 'Cost Component', 'Class I [USD]', 'Class II [USD]');
fprintf('  %s\n', repmat('-',1,65));
fprintf('  %-30s  %15.0f  %15.0f\n', 'Crew Salaries',    cost_crew_total,    cost_crew_total);
fprintf('  %-30s  %15.0f  %15.0f\n', 'Landing Fees',     cost_landing_total, cost_landing_total);
fprintf('  %-30s  %15.0f  %15.0f\n', 'Parking Fees',     cost_parking_total, cost_parking_total);
fprintf('  %-30s  %15.0f  %15.0f\n', 'Fuel Cost',        cost_fuel_total,    cost_fuel_total);
fprintf('  %-30s  %15.0f  %15.0f\n', 'Maintenance',      cost_maint_total,   cost_maint_II_total);
fprintf('  %-30s  %15.0f  %15.0f\n', 'Insurance',        cost_ins_total,     cost_ins_II_total);
fprintf('  %-30s  %15.0f  %15.0f\n', 'Depreciation',     0,                  cost_dep_total);
fprintf('  %-30s  %15.0f  %15.0f\n', 'Interest',         0,                  cost_int_total);
fprintf('  %s\n', repmat('-',1,65));
fprintf('  %-30s  %15.0f  %15.0f\n', 'TOTAL COC (fleet/yr)',  COC_I,  COC_II);
fprintf('  %-30s  %15.0f  %15.0f\n', 'TOTAL DOC (fleet/yr)',  DOC_I,  DOC_II);
fprintf('  %-30s  %15.0f  %15.0f\n', 'DOC per aircraft/yr',   DOC_I/fleet_size, DOC_II/fleet_size);
fprintf('  %s\n', repmat('-',1,65));
fprintf('\n');
fprintf('  Aircraft hull value        : $%.2f M\n', V_hull/1e6);
fprintf('  Per-aircraft purchase cost : $%.2f M  (Class II)\n', C_per_aircraft/1e6);
fprintf('  Total fleet purchase cost  : $%.2f M  (Class II)\n', fleet_size*C_per_aircraft/1e6);
fprintf('\n');
fprintf('  All costs in USD. Fuel: %s. Fleet size: %d aircraft.\n', ...
    fuel_type, fleet_size);
fprintf('=========================================================\n');
fprintf('  Analysis complete. %d figures generated.\n', 4);
fprintf('=========================================================\n\n');


%% =========================================================================
%  LOCAL HELPER FUNCTION (nested, no external file needed)
%  Computes DAPCA IV programme cost for a given production quantity N_p
%  Used only in the fleet size sensitivity loop above.
% =========================================================================
function C_prog = C_lab_scaled(Me,V,N_p,Nft,T_max_kN,M_max,T3_K,N_eng,eta_M)
    H_E = 5.18  * Me^0.777 * V^0.894 * N_p^0.163;
    H_T = 7.22  * Me^0.777 * V^0.696 * N_p^0.263;
    H_M = 10.5  * Me^0.82  * V^0.484 * N_p^0.641;
    H_Q = 0.076 * H_M;
    C_l = (H_E*115 + H_T*118 + H_M*98 + H_Q*108) * eta_M;
    C_D = 67.4  * Me^0.63  * V^1.3;
    C_F = 1947  * Me^0.325 * V^0.822 * Nft^1.21;
    C_m = 31.2  * Me^0.921 * V^0.621 * N_p^0.799;
    C_E = 3112*(9.66*T_max_kN + 243.25*M_max + 1.74*T3_K - 2228) * N_eng;
    C_prog = C_l + C_D + C_F + C_m + C_E;
end