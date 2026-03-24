% Mass estimation at three fidelity levels
%
%   Class I    Raymer Table 15.2 statistical weight fractions
%   Class II   Raymer / Gudmundsson semi-empirical equations
%   Class II.5 Physics-based structural sizing (Torenbeek)
%
% All Class II equations are taken directly from the Group 4 codebase:
%   Wing       +B747/+geom/wing.m
%   Fuselage   +B747/+geom/fuselage.m
%   Empennage  +B747/+geom/empenage.m  (Gudmundsson Eq. 6-49 / 6-53)
%   Gear       +B777/+geom/landingGear.m
%   Engine     +B777/+geom/engine.m

function [CI, CII, CIII] = Estimate(ADP)

% Unit conversion factors (Raymer equations are in lb and ft)
ft  = 3.28084;
lb  = 2.20462;
g   = 9.80665;  % [m/s²]

w  = MassStab.geom.Wing(ADP);

[rho_cruise, a_cruise] = MassStab.geom.Atmos(ADP.TLAR.Alt_cruise);
q_cruise = 0.5 * rho_cruise * (ADP.TLAR.M_c * a_cruise)^2;  % dynamic pressure [Pa]

L_fus        = ADP.CockpitLength + ADP.CabinLength + ADP.CabinRadius * 1.48;
MTOM         = ADP.MTOM;
fuel_mass    = MTOM * ADP.Mf_Fuel;
landing_mass = MTOM * ADP.Mf_Ldg;

% ======================================================================
%  CLASS I  —  Raymer statistical weight fractions (Table 15.2)
%  Quick first-pass estimates directly proportional to MTOM.
%  The folding wingtip adds a 5% penalty to wing mass.
% ======================================================================

CI.W_wing = 0.0440 * MTOM^0.758 * (ADP.Span^2 / ADP.WingArea)^0.6 * (1 + 0.05*ADP.eta_fold);
CI.W_fus  = 0.328  * (L_fus * 2*ADP.CabinRadius)^0.5 * MTOM^0.5;
CI.W_ht   = 0.0379 * ADP.HtpArea^0.639 * MTOM^0.426;
CI.W_vt   = 0.0726 * ADP.VtpArea^0.773 * MTOM^0.217;
CI.W_lg   = 0.0440 * MTOM;
CI.W_prop = ADP.N_eng * ADP.m_eng_each * 1.35;  % engines + 35% for nacelles/mounts
CI.W_sys  = 0.0900 * MTOM;
CI.W_oper = ADP.TLAR.CrewMass + ADP.TLAR.Crew * 140;  % crew + 140 kg bags each
CI.OEW    = CI.W_wing + CI.W_fus + CI.W_ht + CI.W_vt + ...
            CI.W_lg + CI.W_prop + CI.W_sys + CI.W_oper;

% ======================================================================
%  CLASS II  —  Semi-empirical equations (Raymer Ch.15 / Gudmundsson)
% ======================================================================

% Convert to imperial for Raymer equations
span_ft        = ADP.Span    * ft;
S_wing_ft2     = ADP.WingArea * ft^2;
t_root_ft      = 0.15 * w.c_root * ft;       % 15% thickness-to-chord at root
cos_half_sweep = cosd(w.sweep_half);
W_design_lb    = MTOM * ADP.Mf_TOC * lb;     % design weight at top of climb
n_ult          = 2.5 * 1.5;                  % ultimate load factor (CS-25.337)

% Wing mass  —  Raymer Eq. 15.25 (transport aircraft form)
% The folding hinge adds a 5% structural penalty over the folded portion.
CII.W_wing = (0.00125 * W_design_lb                                          ...
    * (span_ft / cos_half_sweep)^0.75                                         ...
    * (1 + sqrt(6.3 * cos_half_sweep / span_ft))                              ...
    * n_ult^0.55                                                               ...
    * (span_ft * S_wing_ft2 / (t_root_ft * W_design_lb * cos_half_sweep))^0.3 ...
    ) / lb * (1 + 0.05 * ADP.eta_fold);

% Fuselage mass  —  Raymer Eq. 15.28
% K_ws accounts for wing-sweep bending relief on the fuselage.
% The 1.5 multiplier corrects for the heavy cargo floor (freighter penalty).
K_ws      = 0.75 * ((1 + 2*w.taper) / (1 + w.taper)) * (span_ft/L_fus) * tand(w.sweep_qc);
D_fus_ft  = 2 * ADP.CabinRadius * ft;
S_wet_fus = pi*D_fus_ft*(ADP.CabinLength*ft) ...
          + pi*(ADP.CabinLength*ft)*(ADP.CabinRadius*ft) ...
          + pi*(1.48*ADP.CabinRadius*ft)*(ADP.CabinRadius*ft);

CII.W_fus = 0.3280 * 1.12 * 1.12                      ...
    * sqrt(W_design_lb * n_ult)                         ...
    * L_fus^0.25 * S_wet_fus^0.302                     ...
    * (1 + K_ws)^0.04 * (L_fus / D_fus_ft)^0.10       ...
    / lb * 1.5;

% Systems mass  —  Torenbeek pressure-system correlation
CII.W_sys = (270 * 2*ADP.CabinRadius + 150) * L_fus / g * 2;

% Fuel system mass  —  Torenbeek (3 tanks: 2 wing + 1 belly)
fuel_vol_litres = fuel_mass / 804 * 1000;   % Jet-A density 804 kg/m³
N_tanks         = 3;
CII.W_fuelsys   = 36.3*(ADP.N_eng + N_tanks - 1) + 4.366*sqrt(N_tanks)*fuel_vol_litres^(1/3);

% HTP mass  —  Gudmundsson Eq. 6-49
% tcr/tct are root and tip thickness ratios; AR_ht = 5 from empenage.m
AR_ht  = 5;
tcr    = 0.15;   tct = 0.12;
tc_avg = (tcr + tct) / 2;

CII.W_ht = 0.016                                                  ...
    * (1.5 * 2.5 * W_design_lb)^0.414                             ...
    * (lb/ft^2 * q_cruise)^0.168                                  ...
    * (ADP.HtpArea * ft^2)^0.896                                  ...
    * (100 * tc_avg / cosd(w.sweep_qc))^(-0.12)                   ...
    * (AR_ht / cosd(w.sweep_qc)^2)^0.043                          ...
    * w.taper^(-0.02) / lb;

% VTP mass  —  Gudmundsson Eq. 6-53
% AR_vt = 3.1 from empenage.m; same sweep angle as HTP assumed
AR_vt = 3.1;

CII.W_vt = 0.073                                                  ...
    * (1.5 * 2.5 * W_design_lb)^0.376                             ...
    * (lb/ft^2 * q_cruise)^0.122                                  ...
    * (ADP.VtpArea * ft^2)^0.873                                  ...
    * (100 * tc_avg / cosd(w.sweep_qc))^(-0.49)                   ...
    * (AR_vt / cosd(w.sweep_qc)^2)^0.357                          ...
    * w.taper^0.039 / lb;

% Landing gear mass  —  Raymer Eq. 15.29 (nose + main gear separately)
landing_mass_lb = landing_mass * lb;
CII.W_lg = (0.125 * (1.5 * landing_mass_lb)^0.566 * (ADP.L_nose_m*ft)^0.845   ...
          + 0.095 * (1.5 * landing_mass_lb)^0.768 * (ADP.L_main_m*ft)^0.409)  ...
          / lb;

% Propulsion mass  —  engine dry mass + Raymer nacelle installation factor
W_nacelle_each = 1.1 * (2.575 * (ADP.m_eng_each*lb)^0.922) / lb - ADP.m_eng_each;
CII.W_prop     = ADP.N_eng * (ADP.m_eng_each + W_nacelle_each);

CII.W_oper   = ADP.TLAR.CrewMass + ADP.TLAR.Crew * 140;
CII.OEW      = CII.W_wing + CII.W_fus + CII.W_ht + CII.W_vt + CII.W_lg ...
             + CII.W_prop + CII.W_sys + CII.W_fuelsys + CII.W_oper;
CII.W_ballast  = max(0, ADP.OEM - CII.OEW);   % residual to reach target OEM
CII.OEW_total  = CII.OEW + CII.W_ballast;

% ======================================================================
%  CLASS II.5  —  Physics-based structural sizing (Torenbeek)
% ======================================================================

rho_al   = 2780;    % density of Al 7075-T6          [kg/m³]
sigma_al = 503e6;   % allowable stress Al 7075-T6     [Pa]  (0.7 × UTS)
safety   = 1.5;     % CS-25 structural safety factor

% Wing  —  bending material index approach (Torenbeek §9.3)
% The root bending moment is reduced by 15% for inertia relief
% (fuel weight and wing self-weight partially cancel lift loads).
n_lim          = 2.5;
M_root_bending = n_lim * MTOM * g * (ADP.Span/2) / 2 * 0.85;
h_wingbox      = 0.55 * 0.12 * w.c_root;    % wingbox height = 55% × t/c × chord
A_cap          = M_root_bending / (sigma_al * h_wingbox/2);   % required cap area
W_bending_mats = rho_al * 2 * A_cap * (ADP.Span/2) * 1.15;   % both caps, taper factor
W_secondary    = 0.30 * W_bending_mats;     % skins, ribs, stringers ≈ 30% of primary
W_fold_mech    = 450 * (1 - ADP.eta_fold) * ADP.Span;   % hinge + actuator mass [kg]
CIII.W_wing    = W_bending_mats + W_secondary + W_fold_mech;

% Fuselage  —  pressure vessel + beam bending (Torenbeek §8.3)
% The 8 psi cabin differential pressure sizes the hoop-stress skin thickness.
delta_p          = 8 * 6894.76;   % 8 psi differential  [Pa]
t_skin           = delta_p * ADP.CabinRadius / (sigma_al / safety);
W_pressure_shell = rho_al * pi * 2*ADP.CabinRadius * L_fus * t_skin;
M_fus_bending    = n_lim * MTOM * g * L_fus / 8;
A_fus_cap        = M_fus_bending / ((sigma_al/safety) * ADP.CabinRadius);
W_fus_bending    = rho_al * 2 * A_fus_cap * L_fus * 1.10;
W_cargo_floor    = 35 * L_fus * 2*ADP.CabinRadius;   % 35 kg/m² reinforced floor
CIII.W_fus       = W_pressure_shell + W_fus_bending + W_cargo_floor;

% HTP  —  sized from aerodynamic bending load on the elevator
b_htp      = sqrt(AR_ht * ADP.HtpArea);
c_root_htp = ADP.HtpArea / ((1 + w.taper)/2 * b_htp);
M_htp_load = 1.1 * q_cruise * 0.30 * ADP.HtpArea * b_htp / 4;
A_cap_htp  = M_htp_load / (sigma_al * 0.45 * c_root_htp * tcr);
CIII.W_ht  = rho_al * A_cap_htp * b_htp * 1.5 * 1.30;  % +30% secondary structure

% VTP  —  sized from one-engine-inoperative yawing moment (CS-25.149)
b_vtp      = sqrt(AR_vt * ADP.VtpArea);
c_root_vtp = ADP.VtpArea / ((1 + w.taper)/2 * b_vtp);
y_engine   = 0.38 * ADP.Span/2;   % inboard engine spanwise position
M_vtp_OEI  = 1.25 * ADP.T_per_eng_kN * 1e3 * y_engine;
A_cap_vtp  = M_vtp_OEI / (sigma_al * 0.45 * c_root_vtp * tcr);
CIII.W_vt  = rho_al * A_cap_vtp * b_vtp * 1.5 * 1.30;

% Landing gear, propulsion, and systems carry over from Class II
% (separate disciplines own those sizing loops)
CIII.W_lg      = CII.W_lg;
CIII.W_prop    = CII.W_prop;
CIII.W_sys     = CII.W_sys;
CIII.W_fuelsys = CII.W_fuelsys;
CIII.W_oper    = CII.W_oper;
CIII.OEW       = CIII.W_wing + CIII.W_fus + CIII.W_ht + CIII.W_vt + CIII.W_lg ...
               + CIII.W_prop + CIII.W_sys + CIII.W_fuelsys + CIII.W_oper;
CIII.W_ballast = max(0, ADP.OEM - CIII.OEW);
CIII.OEW_total = CIII.OEW + CIII.W_ballast;

print_summary(CI, CII, CIII, ADP.OEM);
end


function print_summary(CI, CII, CIII, OEM_target)
labels = {'Wing','Fuselage','HTP','VTP','LG','Propulsion','Systems'};
fields = {'W_wing','W_fus','W_ht','W_vt','W_lg','W_prop','W_sys'};
fprintf('\n%-14s  %8s  %8s  %8s\n', 'Component', 'Class I', 'Class II', 'Class II.5');
fprintf('%s\n', repmat('-',1,46));
for k = 1:numel(labels)
    fprintf('%-14s  %8.1f  %8.1f  %8.1f  t\n', labels{k}, ...
        CI.(fields{k})/1e3, CII.(fields{k})/1e3, CIII.(fields{k})/1e3);
end
fprintf('%s\n', repmat('-',1,46));
fprintf('%-14s  %8.1f  %8.1f  %8.1f  t\n', 'OEW', ...
    CI.OEW/1e3, CII.OEW_total/1e3, CIII.OEW_total/1e3);
fprintf('%-14s  %8s  %+7.1f%%  %+7.1f%%  vs %.0f t target\n', 'Error', '-', ...
    (CII.OEW_total - OEM_target)/OEM_target*100, ...
    (CIII.OEW_total - OEM_target)/OEM_target*100, OEM_target/1e3);
end
