function [GeomObj,massObj,out] = fuselage_myAircraft(obj)
% fuselage_myAircraft
% Same structure as your B777-based code, but filled for YOUR aircraft values:
% MTOW 530 t, Fuel 180 t, OEW 200 t, Span 84.7 m, Lf 76.3 m, D 6.5 m, etc.
%
% IMPORTANT:
% Your table does NOT include cockpit length, cabin length split, cruise Mach, or M_c.
% So this code sets reasonable DEFAULTS for those. Change them at the top if you know them.

%% ------------------------ DEFAULTS (edit if needed) ----------------------
if nargin < 1 || isempty(obj); obj = struct(); end

% Given by you (convert tonnes -> kg)
def.MTOM_kg      = 530e3;     % 530 tonnes
def.Fuel_kg      = 180e3;     % 180 tonnes
def.OEW_kg       = 200e3;     % 200 tonnes (not used directly here)
def.Payload_kg   = 150e3;     % 150 tonnes (not used directly here)
def.Span_m       = 84.7;      % m
def.Lf_m         = 76.3;      % m (overall fuselage length)
def.Diam_m       = 6.5;       % m (outer diameter)
def.Radius_m     = def.Diam_m/2;

% Missing in your table -> choose defaults (EDIT THESE if you know them)
def.CockpitLength_m = 10.0;   % m (typical large transport nose length)
def.Mstar           = 0.84;   % cruise Mach (typical)
def.M_c             = 0.90;   % Mach constraint used in your K_ws expression (typical)

% Optional: if you want the fuselage mass to match your target (28 t),
% set this target and the code will scale the Raymer result to match.
def.TargetFuselageMass_kg = 28e3;  % 28 tonnes (set [] to disable scaling)

% Fuel density (used for tank volume in Torenbeek)
def.rho_fuel_kgm3 = 804;      % Jet-A approx [kg/m^3]

% Load factors / Raymer multipliers (same as your code)
def.K_d  = 1.12;
def.K_Lg = 1.12;
def.n_z  = 2.5 * 1.5;

% Counts
def.N_fuelTank = 3;
def.N_eng      = 2;

% Systems mass correlation factor (your code had "*2"; keep but make it explicit)
def.SysFactor = 2.0;

% -------------------------------------------------------------------------

% Fill obj fields if missing
obj = fillDefault(obj,"MTOM",def.MTOM_kg);
obj = fillDefault(obj,"Span",def.Span_m);

% Geometry fields expected by your original code
obj = fillDefault(obj,"CabinRadius",def.Radius_m);
obj = fillDefault(obj,"CockpitLength",def.CockpitLength_m);

% To keep YOUR total length exactly, compute CabinLength from:
% L_f = CockpitLength + CabinLength + 1.48*CabinRadius
obj = fillDefault(obj,"CabinLength", def.Lf_m - obj.CockpitLength - 1.48*obj.CabinRadius);

% Mass fractions expected by your original code
obj = fillDefault(obj,"Mf_Fuel", def.Fuel_kg/def.MTOM_kg);   % Fuel/MTOW
obj = fillDefault(obj,"Mf_TOC",  0.92);                      % default (edit if you know)
obj = fillDefault(obj,"Mstar",   def.Mstar);
if ~isfield(obj,"TLAR"); obj.TLAR = struct(); end
obj.TLAR = fillDefault(obj.TLAR,"M_c",def.M_c);

% Unit constants (so this runs even if your SI struct is not globally defined)
SI.ft    = 3.280839895;        % ft per m
SI.lb    = 2.2046226218;       % lb per kg
LITRE_PM3 = 1000;              % litres per m^3

%% ---------------------------- Fuselage Geometry --------------------------
% Total length implied by your original formula:
L_f = obj.CockpitLength + obj.CabinLength + obj.CabinRadius * 1.48; % [m]

% cockpit plot points
theta = linspace(0,pi,101)';
Xs = [-sin(theta)*obj.CockpitLength, cos(theta)*obj.CabinRadius];

% tail plot points (same shape logic as your code)
theta = linspace(pi,0,101)';
Xs = [Xs; ...
    sin(theta)*obj.CabinRadius*2*2.48 + (obj.CabinLength - obj.CabinRadius*2), ...
    cos(theta)*obj.CabinRadius];

% tidy up geometry points
Xs(:,1) = Xs(:,1) + obj.CockpitLength;  % ensure start from zero
GeomObj = cast.GeomObj(Name="Fuselage", Xs=Xs);

%% ---------------------------- Fuselage Mass ------------------------------
K_d  = def.K_d;
K_Lg = def.K_Lg;

M_dg = obj.MTOM * obj.Mf_TOC * SI.lb;     % design weight at TOC [lb]
n_z  = def.n_z;
D    = (2 * obj.CabinRadius) * SI.ft;     % max fuselage diameter [ft]
b_w  = obj.Span * SI.ft;                  % wing span [ft]
L_f_ft = L_f * SI.ft;                     % fuselage length [ft] (IMPORTANT: convert!)

% Wing geometry influence (Raymer's K_ws) – keep your method
SweepQtrChord = real(acosd(0.75 .* obj.Mstar ./ obj.TLAR.M_c)); % [deg]
tr  = -0.0083 * SweepQtrChord + 0.4597;                          % taper estimate
K_ws = 0.75 * ((1 + 2*tr) / (1 + tr)) * (b_w / L_f_ft) * tand(SweepQtrChord);

% Fuselage wetted area (simple, consistent first-order):
% barrel wetted area + nose/tail “cap” allowance
S_barrel = pi * D * (obj.CabinLength * SI.ft);      % [ft^2]
S_caps   = 0.5 * pi * (D^2);                        % [ft^2] rough allowance
S_f = S_barrel + S_caps;

% Raymer correlation (weight in lb)
W_fus_lb = 0.3280 * K_d * K_Lg * sqrt(M_dg * n_z) * (L_f_ft^0.25) * (S_f^0.302) ...
           * ((1 + K_ws)^0.04) * ((L_f_ft / D)^0.10);

% Convert to mass [kg]
m_fus_kg_raw = W_fus_lb / SI.lb;

% OPTIONAL: scale to hit your target fuselage mass (28 t)
if ~isempty(def.TargetFuselageMass_kg)
    scale = def.TargetFuselageMass_kg / m_fus_kg_raw;
else
    scale = 1.0;
end
m_fus_kg = m_fus_kg_raw * scale;

massObj = cast.MassObj(Name="Fuselage", m=m_fus_kg, X=[L_f/2;0]);

%% ----------------------------- Systems Mass ------------------------------
m_sys = (270*(2*obj.CabinRadius) + 150) * L_f / 9.81 * def.SysFactor;
massObj(end+1) = cast.MassObj(Name="Systems", m=m_sys, X=[L_f/2;0]);

%% --------------------------- Fuel System Mass ----------------------------
FuelMass = obj.MTOM * obj.Mf_Fuel;                 % [kg]
V_t_L = (FuelMass / def.rho_fuel_kgm3) * LITRE_PM3; % total volume [litres]
N_fuelTank = def.N_fuelTank;
N_eng = def.N_eng;

m_fuelsys = (36.3*(N_eng + N_fuelTank - 1) + 4.366*sqrt(N_fuelTank)*V_t_L^(1/3)); % Torenbeek-style
massObj(end+1) = cast.MassObj(Name="Fuel Systems", m=m_fuelsys, X=[L_f/2;0]);

%% ------------------------------- Outputs --------------------------------
out.L_f_m         = L_f;
out.CabinLength_m = obj.CabinLength;
out.CockpitLength_m = obj.CockpitLength;
out.Radius_m      = obj.CabinRadius;
out.Diameter_m    = 2*obj.CabinRadius;
out.Mf_Fuel       = obj.Mf_Fuel;
out.Mf_TOC        = obj.Mf_TOC;
out.SweepQtr_deg  = SweepQtrChord;
out.K_ws          = K_ws;
out.S_wet_ft2     = S_f;
out.W_fus_lb      = W_fus_lb;
out.m_fus_kg_raw  = m_fus_kg_raw;
out.scale_to_target = scale;

end

% ------------------------------ helper -----------------------------------
function s = fillDefault(s, field, value)
if ~isfield(s,field) || isempty(s.(field))
    s.(field) = value;
end
end