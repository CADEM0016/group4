%% =========================================================================
%  CADEM0016  |  GDP Group 3  |  University of Bristol  2025/26
%  -------------------------------------------------------------------------
%  MASS & STABILITY ENGINEER  —  Standalone Script
%  -------------------------------------------------------------------------
%  Aircraft  : Modified Boeing 777 Wide-body Cargo Freighter
%  Mission   : Formula 1 air cargo transport  (EIS 2040)
%
%  Source files  (parameters extracted; codes NOT integrated):
%    fuselage_final_1_m.txt        All mass/arm/geometry/stability inputs
%    WingStructuralAnalysis (2).m  ADP sizing setup + ws struct fields
%
%  DATUM : Nose tip of fuselage  (x = 0)
%  CG formula: CG = SUM(m_i × x_i) / SUM(m_i)   [NO LEMAC offset]
%
%  Figures produced
%    1  OEW component breakdown   (Class I / II / II.5 grouped bar)
%    2  CG potato diagram         (two loading sequences + NP limits)
%    3  CG migration during fuel burn  (belly-first strategy)
%    4  Static margin sensitivity to HTP area
%    5  CG & NP on fuselage side profile  (style: fuselage Fig 1 / 8)
%    6  OEW mass pie chart        (Class II.5)
%    7  Empennage sizing trades   (HTP and VTP moment-arm sweeps)
%    8  Wing structural load distributions  (BM, SF, spar cap area)
% =========================================================================

clc;  clear;  close all;

%% =========================================================================
%  BLOCK 1  :  AUTHORITATIVE MASS & ARM INPUTS
%  Source : fuselage_final_1_m.txt  Section 1  —  every line verbatim
%  All arms in metres from nose  (datum = nose tip, x = 0)
% =========================================================================

% ---- Weights (Section 1) ------------------------------------------------
MTOW      = 530000;   % [kg]  Maximum take-off weight
OEW       = 200000;   % [kg]  Operating empty weight
Fuel      = 180000;   % [kg]  Total fuel (3 × 60 000 kg)
Payload   = 150000;   % [kg]  Payload (F1 cargo)

Fus_mass  =  28000;   % [kg]  Fuselage structure
Tail_mass =  12800;   % [kg]  Tail assembly
Wing_mass =  38000;   % [kg]  Wing structure

Fuel_fus  =  60000;   % [kg]  Belly tank
Fuel_wing =  60000;   % [kg]  Each wing tank (left = right)

% ---- Authoritative CG arms from nose (Section 1) ------------------------
x_OEW     =  33.50;   % [m]  Empty CG (specified)
x_payload =  34.27;   % [m]  Cargo CG (specified)
x_fb      =  36.80;   % [m]  Belly tank arm (specified)
x_fw      =  35.50;   % [m]  Each wing tank arm (specified, left = right)
LEMAC     =  31.50;   % [m]  Leading edge of wing from nose (specified)

% ---- Geometry (Section 1) -----------------------------------------------
L_fus     =  76.3;    % [m]
D_fus     =   6.5;    % [m]
S_wing    =  600;     % [m²]
b_wing    =   71;     % [m]
Cr        =  13.2;    % [m]  root chord
Ct        =   3.7;    % [m]  tip chord
VH        =   0.5;   % [-]  H-tail volume coefficient (specified)
VV        =   0.06;   % [-]  V-tail volume coefficient5 (specified)
Lh        =  33.50;   % [m]  H-tail moment arm (specified)
Lv        =  33.00;   % [m]  V-tail moment arm (specified)

R_fus     = D_fus / 2;             % 3.25 m
R_in      = R_fus - 0.06;          % 3.19 m  inner pressure shell
g         = 9.81;                   % [m/s²]
sweep_deg =  28;
SW        = tan(sweep_deg * pi / 180);
semi_sp   = b_wing / 2;             % 35.5 m
lambda    = Ct / Cr;                % 0.2803
MAC       = (2/3)*Cr*((1+lambda+lambda^2)/(1+lambda));  % 9.3400 m
AR        = b_wing^2 / S_wing;     % 8.4017

t_skin    = 0.004;    % [m]   fuselage skin thickness
sig_yld   = 345e6;    % [Pa]  yield stress
sig_ult   = 483e6;    % [Pa]  ultimate stress
alt_cr    = 10668;    % [m]   cruise altitude
M_cr      =  0.84;
frame_pitch = 0.508;
n_str_fus   =  72;

%% =========================================================================
%  BLOCK 2  :  WING STRUCTURAL PARAMETERS
%  Source : WingStructuralAnalysis (2).m  —  ADP setup values (Step 1) and
%           ws struct field names (Steps 2-5)  —  verbatim
% =========================================================================

% ---- ADP sizing setup (WingStructuralAnalysis Step 1) ------------------
ADP_Span        = 64.8;            % [m]   wing span used in wing analysis
ADP_KinkPos     = 10;              % [m]
ADP_CabinRadius =  3.1;            % [m]
ADP_CabinLength = 63.7 - 6 - 3.1*2*1.48;
ADP_WingPos     = 0.44 * 63.7;    % [m]   28.028 m
ADP_V_HT        = 0.75;
ADP_V_VT        = 0.07;
ADP_HtpPos      = 0.85 * 63.7;
ADP_VtpPos      = 0.82 * 63.7;
ADP_M_c         = 0.84;
ADP_Mf_Fuel     = 0.19;
ADP_Mf_res      = 0.03;
ADP_Mf_Ldg      = 0.68;
ADP_Mf_TOC      = 0.97;

% Wing semi-span and engine positions (WingStructuralAnalysis Step 2)
b_half_ws = ADP_Span / 2;         % 32.4 m
y_eng1    = b_half_ws * 0.35;     % 11.340 m  inner engines (35% semi-span)
y_eng2    = b_half_ws * 0.70;     % 22.680 m  outer engines (70% semi-span)

% ---- Wing structural geometry (ws.geom fields from Step 3) -------------
%  Airfoil: NACA-like, t/c varies 12% (root) → 10% (tip)
%  Front spar at 15% chord, rear spar at 65% chord
ws_c_r          = Cr;              % [m]  root chord (same as fuselage)
ws_c_t          = Ct;              % [m]  tip chord
ws_S            = S_wing;          % [m²]
ws_SweepQtrChord = sweep_deg;      % [°]

% ---- Load factors (WingStructuralAnalysis Step 3 tile 2/3) -------------
ws_n_limit = 2.5;                  % CS-25.337
ws_n_ult   = ws_n_limit * 1.5;    % 3.75g

% ---- Spanwise distributions (WingStructuralAnalysis, used in Step 3) ---
%  These are recomputed here so that distributions are available for Fig 8
n_span_ws = 200;
y_s_ws    = linspace(0, b_half_ws, n_span_ws);
c_s_ws    = ws_c_r - (ws_c_r - ws_c_t).*(y_s_ws / b_half_ws);
tc_s_ws   = 0.12 - 0.02.*(y_s_ws / b_half_ws);   % t/c: 12%→10%

%  NACA 64A thickness (from WingStructuralAnalysis tile 4 airfoil equation)
%  z_thick = (tc/0.20)×c×(0.2969√x - 0.126x - 0.3516x² + 0.2843x³ - 0.1015x⁴)
naca_yt = @(x_frac, tc) (tc/0.20).*(0.2969*sqrt(x_frac) - 0.126*x_frac ...
          - 0.3516*x_frac.^2 + 0.2843*x_frac.^3 - 0.1015*x_frac.^4);
x_fs = 0.15;  x_rs = 0.65;   % spar chord fractions

h_fs_s = 2 * naca_yt(x_fs, tc_s_ws) .* c_s_ws;
h_rs_s = 2 * naca_yt(x_rs, tc_s_ws) .* c_s_ws;
h_box_s = 0.5*(h_fs_s + h_rs_s);
w_box_s = (x_rs - x_fs).*c_s_ws;
h_box_root_ws = h_box_s(1);
w_box_root_ws = w_box_s(1);

%  Lift distribution (Schrenk: trapezoidal + elliptic, WingStructuralAnalysis tile 2)
W_total_ws  = MTOW * g;
w_trap_ws   = c_s_ws / (S_wing/2);
w_ellip_ws  = (4/(pi*ADP_Span)).*sqrt(max(0, 1-(2*y_s_ws/ADP_Span).^2));
w_schrenk_ws = 0.5*(w_trap_ws + w_ellip_ws);
lift_ws      = W_total_ws * w_schrenk_ws;

%  Engine inertia relief (WingStructuralAnalysis tile 2)
m_eng_ws    = MTOW * 0.013;
W_eng_ws    = m_eng_ws * g;

M_lift_root_ws  = trapz(y_s_ws, lift_ws.*y_s_ws);
M_eng_rel_ws    = 2*W_eng_ws*(y_eng1+y_eng2);
M_root_1g_ws    = M_lift_root_ws - M_eng_rel_ws;
ws_M_root_ult   = M_root_1g_ws * ws_n_ult;    % ws.loads.M_root_ult

V_lift_root_ws  = trapz(y_s_ws, lift_ws);
V_eng_rel_ws    = 2*W_eng_ws*2;
ws_V_root_ult   = (V_lift_root_ws - V_eng_rel_ws)*ws_n_ult;  % ws.loads.V_root_ult
ws_M_eng_relief = M_eng_rel_ws * ws_n_ult;    % ws.loads.M_eng_relief

%  Spanwise BM distribution (WingStructuralAnalysis tile 2)
relief_ws = max(0, 1 - y_s_ws/y_eng2);
M_dist_ws = zeros(1, n_span_ws);
for k = 1:n_span_ws
    ys_out = y_s_ws(k:end);
    if numel(ys_out) < 2,  M_dist_ws(k) = 0;  continue;  end
    M_dist_ws(k) = trapz(ys_out, lift_ws(k:end).*(ys_out-y_s_ws(k)));
end
M_dist_ws = max(0, M_dist_ws - M_eng_rel_ws.*relief_ws).*ws_n_ult;

%  Spanwise SF distribution (WingStructuralAnalysis tile 3)
V_dist_ws = zeros(1, n_span_ws);
for k = 1:n_span_ws
    ys_out = y_s_ws(k:end);
    if numel(ys_out) < 2,  V_dist_ws(k) = 0;  continue;  end
    V_dist_ws(k) = trapz(ys_out, lift_ws(k:end));
end
V_dist_ws = max(0, V_dist_ws - V_eng_rel_ws.*relief_ws).*ws_n_ult;

% ---- Material (CFRP — consistent with wing analysis t/c and thickness) --
rho_cfrp     = 1580;      % [kg/m³]
E_cfrp       = 161e9;     % [Pa]
nu_cfrp      = 0.30;
sigma_ult_c  = 1435e6;    % [Pa]  CFRP IM7/8552
t_ply        = 0.125e-3;  % [m]
SF_wing      = 1.5;
sigma_allow  = sigma_ult_c / SF_wing;
tau_allow    = sigma_allow * 0.60;

% ---- Spar cap sizing (WingStructuralAnalysis tile 4) -------------------
A_cap_dist_ws = M_dist_ws ./ (sigma_allow .* h_box_s);
A_cap_dist_ws = max(A_cap_dist_ws, 4*t_ply*0.03);
A_cap_root_ws = A_cap_dist_ws(1);
t_cap_root_ws = A_cap_root_ws / w_box_root_ws;
n_plies_cap_ws = max(4, ceil(t_cap_root_ws / t_ply));
t_cap_ws      = n_plies_cap_ws * t_ply;         % ws.sizing.t_cap
A_cap_ws      = t_cap_ws * w_box_root_ws;        % ws.sizing.w_box_root used here

vol_cap_ws    = 2*2*trapz(y_s_ws, A_cap_dist_ws);
ws_m_spar_cap = vol_cap_ws * rho_cfrp;           % ws.mass.m_spar_cap

% ---- Web sizing (WingStructuralAnalysis tile 5) ------------------------
t_web_dist_ws = V_dist_ws ./ (tau_allow .* h_box_s);
t_web_dist_ws = max(t_web_dist_ws, 2*t_ply);
t_web_root_ws = t_web_dist_ws(1);
n_plies_web_ws = max(2, ceil(t_web_root_ws / t_ply));
t_web_ws      = n_plies_web_ws * t_ply;          % ws.sizing.t_web

vol_web_ws    = 2*2*trapz(y_s_ws, t_web_dist_ws.*h_box_s);
ws_m_web      = vol_web_ws * rho_cfrp;            % ws.mass.m_web

% ---- Skin sizing -------------------------------------------------------
rib_pitch_ws  = 0.75;   % [m]  (from tile 4 plot annotations)
k_buckle      = 4.0;
sigma_skin_root = ws_M_root_ult*(h_box_root_ws/2) / ...
    (A_cap_ws*(h_box_root_ws/2)^2 + ...
     (1/12)*w_box_root_ws*h_box_root_ws^3/h_box_root_ws^2);
t_skin_buckle = rib_pitch_ws*sqrt(sigma_skin_root*12*(1-nu_cfrp^2) / ...
                    (k_buckle*pi^2*E_cfrp));
t_skin_DT     = 4*t_ply;
t_skin_ws_val = max(t_skin_buckle, t_skin_DT);
n_plies_skin_ws = max(4, ceil(t_skin_ws_val/t_ply));
t_skin_ws     = n_plies_skin_ws * t_ply;          % ws.sizing.t_skin
S_wetted_ws   = 2.07 * S_wing;
ws_m_skin     = S_wetted_ws * t_skin_ws * rho_cfrp;  % ws.mass.m_skin

% ---- Rib sizing --------------------------------------------------------
n_ribs_half_ws = floor(b_half_ws / rib_pitch_ws);  % ws.sizing.n_ribs_half
t_rib_web_ws   = max(2*t_ply, 2.5e-3);
f_rib_cap_ws   = 1.15;
y_ribs_ws      = (1:n_ribs_half_ws)*rib_pitch_ws;
y_ribs_ws      = y_ribs_ws(y_ribs_ws <= b_half_ws);
c_ribs_ws      = ws_c_r - (ws_c_r-ws_c_t).*(y_ribs_ws/b_half_ws);
tc_ribs_ws     = 0.12 - 0.02.*(y_ribs_ws/b_half_ws);
h_fs_ribs_ws   = 2*naca_yt(x_fs, tc_ribs_ws).*c_ribs_ws;
h_rs_ribs_ws   = 2*naca_yt(x_rs, tc_ribs_ws).*c_ribs_ws;
h_box_ribs_ws  = 0.5*(h_fs_ribs_ws + h_rs_ribs_ws);
w_box_ribs_ws  = (x_rs-x_fs).*c_ribs_ws;
rib_perim_ws   = 2*(h_box_ribs_ws + w_box_ribs_ws);
m_rib_each_ws  = rib_perim_ws.*t_rib_web_ws.*rho_cfrp.*f_rib_cap_ws;
ws_m_ribs      = sum(m_rib_each_ws)*2;             % ws.mass.m_ribs

% ---- Secondary structure (pie chart tile 6: labelled 'Secondary') ------
ws_m_primary   = ws_m_spar_cap + ws_m_web + ws_m_skin + ws_m_ribs;
f_secondary_ws = 0.41;
ws_m_secondary = ws_m_primary * f_secondary_ws;    % ws.mass.m_secondary

% ---- Total wing mass (ws.mass.m_total) ---------------------------------
ws_m_total    = ws_m_primary + ws_m_secondary;

% ---- Margins of safety (WingStructuralAnalysis Step 5) -----------------
sigma_act_cap = ws_M_root_ult / (A_cap_ws * h_box_root_ws);
ws_MS_bending = sigma_allow / sigma_act_cap - 1;   % ws.margins.MS_bending

tau_act_web   = ws_V_root_ult / (t_web_ws * h_box_root_ws);
ws_MS_shear   = tau_allow  / tau_act_web  - 1;     % ws.margins.MS_shear

%% =========================================================================
%  BLOCK 3  :  FUEL CG & MTOW CG
%  Source : fuselage_final_1_m.txt  Section 2  —  verbatim formula
% =========================================================================

%  Combined fuel CG — mass-weighted across all three tanks
CG_fuel_total = (Fuel_fus*x_fb + Fuel_wing*x_fw + Fuel_wing*x_fw) / Fuel;
%  = (60000×36.8 + 60000×35.5 + 60000×35.5) / 180000 = 35.933 m
CG_fuel = CG_fuel_total;

%  ZFW CG
CG_ZFW = (OEW*x_OEW + Payload*x_payload) / (OEW + Payload);
%  = (200000×33.5 + 150000×34.27) / 350000 = 33.830 m

%  MTOW CG — SUM(m_i × x_i) / SUM(m_i), NO LEMAC offset
CG_MTOW_comp = (OEW*x_OEW + Fuel*CG_fuel_total + Payload*x_payload) / MTOW;

% ---- SPECIFIED DESIGN OVERRIDES -----
CG_MTOW = 34.54;   % specified design CG at MTOW (m from nose)
NP      = 36.43;   % specified neutral point      (m from nose)

%% =========================================================================
%  BLOCK 4  :  STABILITY  —  NEUTRAL POINT & STATIC MARGINS
%  Source : fuselage_final_1_m.txt  Section 3  —  verbatim formula
% =========================================================================

%  Wing aerodynamic centre = LEMAC + 25% MAC
x_AC_wing = LEMAC + 0.25*MAC;              % 30 + 0.25×9.34 = 32.335 m

%  Tail areas from volume coefficients
S_H_NP = VH * S_wing * MAC / Lh;          % 100.371 m²  (for NP calc)
S_V_NP = VV * S_wing * b_wing / Lv;       %  77.455 m²

%  Horizontal tail AC
x_AC_tail = x_AC_wing + Lh;               % 32.335 + 33.5 = 65.835 m

%  NP — wing + tail weighted by lift-slope areas (fuselage file formula)
NP_formula = (x_AC_wing*S_wing + x_AC_tail*S_H_NP) / (S_wing + S_H_NP);
%  = (32.335×600 + 65.835×100.371) / (600 + 100.371) = 37.136 m

%  Static margins at each loading condition (fuselage file Section 3)
SM_MTOW = (NP - CG_MTOW) / MAC * 100;    % 20.24% MAC [OK]
SM_ZFW  = (NP - CG_ZFW)  / MAC * 100;    % 27.84% MAC [OK]
SM_OEW  = (NP - x_OEW)   / MAC * 100;    % 31.37% MAC [OK]

%% =========================================================================
%  BLOCK 5  :  BELLY TANK GEOMETRY
%  Source : fuselage_final_1_m.txt  Section 4  —  verbatim
% =========================================================================

rho_fuel  = 800;                            % [kg/m³]  Jet-A
V_reqd    = Fuel_fus / rho_fuel;            % 75.00 m³

lh_floor_y = -1.85;                         % lower hold floor y  [m]
belly_top  = lh_floor_y - 0.12;            % -1.97 m  (below floor beam)
keel_y     = -R_in;                         % -3.19 m
d_chord    = abs(belly_top);
alpha_seg  = acos(d_chord / R_in);
A_seg = R_in^2*alpha_seg - d_chord*sqrt(R_in^2 - d_chord^2);  % 4.2683 m²

L_tank     = 18.0;                          % [m]  tank length
x_tank_fwd = x_fb - L_tank/2;              % 27.80 m
x_tank_aft = x_fb + L_tank/2;              % 45.80 m
tank_vol_fus  = A_seg * L_tank;            % 76.829 m³
tank_fill_pct = V_reqd / tank_vol_fus * 100;  % 97.6%

belly_hw      = sqrt(max(0, R_in^2 - lh_floor_y^2));
tank_w        = 2*belly_hw;                 % 5.018 m full width
tank_hw_top   = sqrt(max(0, R_in^2 - belly_top^2));

%  Wing tank volume (from fuselage file Section 4)
c_avg        = (Cr + Ct) / 2;
t_c_ratio    = 0.12;
wing_box_frac = 0.50;
tank_vol_wing = (semi_sp - R_fus)*c_avg*t_c_ratio*wing_box_frac*0.85;

%% =========================================================================
%  BLOCK 6  :  FUSELAGE GEOMETRY & STRUCTURAL CHECKS
%  Source : fuselage_final_1_m.txt  Section 6  —  verbatim
% =========================================================================

SR = L_fus / D_fus;                         % 11.738
fineness_ok = (SR >= 8) && (SR <= 14);

nose_frac = 0.12;  tail_frac = 0.14;  body_frac = 0.74;
L_nose = L_fus*nose_frac;                   %  9.156 m
L_body = L_fus*body_frac;                   % 56.462 m
L_tail = L_fus*tail_frac;                   % 10.682 m

S_H = (VH * S_wing * MAC) / Lh;             % 100.371 m²
S_V = (VV * S_wing * b_wing) / Lv;          %  77.455 m²

S_wet_fus = pi*D_fus*L_fus*(1-2/SR)^(2/3)*(1+1/SR^2);
WL = (MTOW*g) / S_wing;

%  ISA at cruise (fuselage file Section 6)
if alt_cr <= 11000
    T_cr = 288.15 - 0.0065*alt_cr;
    P_cr = 101325*(T_cr/288.15)^5.2561;
else
    T_cr = 216.65;
    P_cr = 101325*(216.65/288.15)^5.2561 * exp(-g*(alt_cr-11000)/(287.05*216.65));
end
rho_cr = P_cr/(287.05*T_cr);
V_cr   = M_cr*sqrt(1.4*287.05*T_cr);
q_cr   = 0.5*rho_cr*V_cr^2;

P_cabin  = 101325*(1-0.0065*1828/288.15)^5.2561;
dP       = P_cabin - P_cr;
sig_hoop = (dP*R_fus)/t_skin;               % 46.61 MPa
sig_long = (dP*R_fus)/(2*t_skin);
SF_hoop  = sig_yld/sig_hoop;                % 7.40
SF_long  = sig_yld/sig_long;

BM_max = (Fus_mass*g/2)*(L_fus/4)*2.5;     % 6.549 MN.m

%  Floor geometry (fuselage file Section 6)
ud_floor_y  =  0.00;
ud_floor_hw = sqrt(max(0,R_in^2-ud_floor_y^2))*0.94;
lh_floor_hw = sqrt(max(0,R_in^2-lh_floor_y^2))*0.90;

%  Fuselage profile (fuselage file Section 6)
Nn=max(round(600*nose_frac),20); Nb=max(round(600*body_frac),20); Nt=max(round(600*tail_frac),20);
xn=linspace(0,L_nose,Nn);              rn=R_fus*0.5.*(1-cos(pi.*xn./L_nose));
xb=linspace(L_nose,L_nose+L_body,Nb); rb=R_fus*ones(1,Nb);
xt=linspace(L_nose+L_body,L_fus,Nt);
rt=R_fus.*(0.12+0.88.*0.5.*(1+cos(pi.*(xt-(L_nose+L_body))./L_tail)));
xp=[xn,xb(2:end),xt(2:end)];  rp=[rn,rb(2:end),rt(2:end)];

%  Belly tank cross-section polygon (fuselage file Section 6, FIXED formula)
th_tank   = linspace(pi+asin(abs(belly_top)/R_in), 2*pi-asin(abs(belly_top)/R_in), 200);
tank_arc_x = R_in.*cos(th_tank);
tank_arc_y = R_in.*sin(th_tank);
tank_poly_x = [tank_arc_x,  tank_hw_top, -tank_hw_top];
tank_poly_y = [tank_arc_y,  belly_top,    belly_top];

%  V-tail geometry (fuselage file Section 6)
VT_chord_root = 9.0;  VT_chord_tip = 4.5;
VT_height     = S_V / ((VT_chord_root+VT_chord_tip)/2);
VT_sweep_tan  = tan(40*pi/180);
hx0           = L_fus * 0.87;
VT_LE_root_x  = hx0;
VT_TE_root_x  = hx0 + VT_chord_root;
VT_LE_tip_x   = hx0 + VT_height*VT_sweep_tan;
VT_TE_tip_x   = VT_LE_tip_x + VT_chord_tip;
VT_root_y     = R_fus;
VT_tip_y      = R_fus + VT_height;

% MAC eta (used in figures)
eta_mac = (1+2*lambda)/(3*(1+lambda));
wx0     = LEMAC;    % wing LE fixed at 30 m from nose (Section 3 of fuselage file)

%% =========================================================================
%  BLOCK 7  :  F1 PALLET SPECIFICATION
%  Source : fuselage_final_1_m.txt  Section 5  —  verbatim
% =========================================================================

P6P_W=2.435; P6P_L=3.175; P6P_H=1.626; P6P_mass=3000;
P6Pp_W=2.435; P6Pp_L=4.978; P6Pp_H=1.626; P6Pp_mass=2500;
n_teams=12; team_P6P=13; F1_own_P6P=86; F1_own_P6Pp=4;
total_P6P  = n_teams*team_P6P + F1_own_P6P;
total_P6Pp = F1_own_P6Pp;
total_cargo_mass = total_P6P*P6P_mass + total_P6Pp*P6Pp_mass;

%% =========================================================================
%  BLOCK 8  :  MASS BUDGET  (three fidelity levels)
%  Formulae unchanged from previous standalone; inputs updated to new file
% =========================================================================

ft = 3.28084;  lb = 2.20462;

% ---- Class I  (Raymer Table 15.2) --------------------------------------
CI_W_wing = 0.0440*MTOW^0.758*AR^0.6;
CI_W_fus  = 0.328*(L_fus*D_fus)^0.5*MTOW^0.5;
CI_W_ht   = 0.0379*S_H^0.639*MTOW^0.426;
CI_W_vt   = 0.0726*S_V^0.773*MTOW^0.217;
CI_W_lg   = 0.0440*MTOW;
CI_W_prop = 4*7000*1.35;
CI_W_sys  = 0.0900*MTOW;
CI_W_oper = 4*90 + 4*140;
CI_OEW    = CI_W_wing+CI_W_fus+CI_W_ht+CI_W_vt+CI_W_lg ...
           +CI_W_prop+CI_W_sys+CI_W_oper;

% ---- Class II  (Raymer Ch.15 / Gudmundsson) ----------------------------
W_dg_lb  = MTOW*ADP_Mf_TOC*lb;
span_ft  = b_wing*ft;
S_ft2    = S_wing*ft^2;
t_root_ft = 0.15*Cr*ft;
cos_sw   = cosd(sweep_deg);
n_ult_II = 3.75;

CII_W_wing = (0.00125*W_dg_lb*(span_ft/cos_sw)^0.75 ...
    *(1+sqrt(6.3*cos_sw/span_ft))*n_ult_II^0.55 ...
    *(span_ft*S_ft2/(t_root_ft*W_dg_lb*cos_sw))^0.3)/lb;

K_ws      = 0.75*((1+2*lambda)/(1+lambda))*(span_ft/(L_fus*ft))*tand(sweep_deg);
D_ft      = D_fus*ft;
S_wet_ft2 = pi*D_ft*(L_body*ft)+pi*(L_body*ft)*(R_fus*ft)+pi*1.48*R_fus*ft*R_fus*ft;
CII_W_fus = 0.3280*1.12*1.12*sqrt(W_dg_lb*n_ult_II)*(L_fus*ft)^0.25 ...
    *S_wet_ft2^0.302*(1+K_ws)^0.04*(L_fus/D_fus)^0.10/lb*1.5;

tc_avg_ht = (0.15+0.12)/2;
AR_ht     = 5;
CII_W_ht  = 0.016*(1.5*2.5*W_dg_lb)^0.414*(lb/ft^2*q_cr)^0.168 ...
    *(S_H*ft^2)^0.896*(100*tc_avg_ht/cos_sw)^(-0.12) ...
    *(AR_ht/cos_sw^2)^0.043*lambda^(-0.02)/lb;

AR_vt     = 3.1;
CII_W_vt  = 0.073*(1.5*2.5*W_dg_lb)^0.376*(lb/ft^2*q_cr)^0.122 ...
    *(S_V*ft^2)^0.873*(100*tc_avg_ht/cos_sw)^(-0.49) ...
    *(AR_vt/cos_sw^2)^0.357*lambda^0.039/lb;

M_ldg_lb  = MTOW*ADP_Mf_Ldg*lb;
CII_W_lg  = (0.125*(1.5*M_ldg_lb)^0.566*(3.6*ft)^0.845 ...
           + 0.095*(1.5*M_ldg_lb)^0.768*(5.0*ft)^0.409)/lb;
W_nac_each = 1.1*(2.575*(7000*lb)^0.922)/lb - 7000;
CII_W_prop = 4*(7000+W_nac_each);
CII_W_sys  = (270*D_fus+150)*L_fus/g*2;
CII_W_fsys = 36.3*(4+3-1)+4.366*sqrt(3)*(Fuel/804*1000)^(1/3);
CII_W_oper = 4*90+4*140;

CII_OEW    = CII_W_wing+CII_W_fus+CII_W_ht+CII_W_vt+CII_W_lg ...
           + CII_W_prop+CII_W_sys+CII_W_fsys+CII_W_oper;
CII_ballast  = max(0, OEW-CII_OEW);
CII_OEW_tot  = CII_OEW + CII_ballast;

% ---- Class II.5  (physics-based) ---------------------------------------
%  Wing  : ws_m_total from WingStructuralAnalysis (above)
%  Fuselage : Fus_mass from fuselage_final_1_m.txt (28 000 kg)
CII5_W_wing  = ws_m_total;
CII5_W_fus   = Fus_mass;
CII5_W_ht    = CII_W_ht;
CII5_W_vt    = CII_W_vt;
CII5_W_lg    = CII_W_lg;
CII5_W_prop  = CII_W_prop;
CII5_W_sys   = CII_W_sys;
CII5_W_fsys  = CII_W_fsys;
CII5_W_oper  = CII_W_oper;

CII5_OEW     = CII5_W_wing+CII5_W_fus+CII5_W_ht+CII5_W_vt+CII5_W_lg ...
             + CII5_W_prop+CII5_W_sys+CII5_W_fsys+CII5_W_oper;
CII5_ballast  = max(0, OEW-CII5_OEW);
CII5_OEW_tot  = CII5_OEW + CII5_ballast;

%% =========================================================================
%  BLOCK 9  :  CONSOLE OUTPUT
% =========================================================================

fprintf('\n');
fprintf('=================================================================\n');
fprintf('  CADEM0016  |  GDP Group 3  |  Mass & Stability Engineer\n');
fprintf('  Modified B777 Cargo  —  Formula 1 2040 Mission\n');
fprintf('  Datum: Nose tip (x = 0)  |  CG = SUM(m*x)/SUM(m)  [no LEMAC offset]\n');
fprintf('=================================================================\n');

fprintf('\n--- AUTHORITATIVE MASS & ARM INPUTS (fuselage_final_1_m.txt) ----\n');
fprintf('  %-32s %10.3f  %s\n','x_OEW  (spec)',   x_OEW,    'm');
fprintf('  %-32s %10.3f  %s\n','x_payload (spec)',x_payload,'m');
fprintf('  %-32s %10.3f  %s\n','x_fb belly tank (spec)',x_fb,'m');
fprintf('  %-32s %10.3f  %s\n','x_fw wing tanks (spec)',x_fw,'m');
fprintf('  %-32s %10.3f  %s\n','LEMAC (spec)',    LEMAC,    'm');

fprintf('\n--- FUEL & CG (Section 2, verbatim formula) ---------------------\n');
fprintf('  CG_fuel_total = (%.0f×%.2f + 2×%.0f×%.2f)/%.0f = %.4f m\n', ...
        Fuel_fus,x_fb,Fuel_wing,x_fw,Fuel,CG_fuel_total);
fprintf('  CG_ZFW        = (%.0f×%.2f + %.0f×%.3f)/%.0f = %.4f m\n', ...
        OEW,x_OEW,Payload,x_payload,OEW+Payload,CG_ZFW);
fprintf('  CG_MTOW       = %.4f m  (specified design value)\n', CG_MTOW);
fprintf('  [Cross-check:  computed = %.4f m]\n', CG_MTOW_comp);

fprintf('\n--- STABILITY (Section 3, verbatim formula) ---------------------\n');
fprintf('  x_AC_wing = LEMAC + 0.25×MAC = %.3f m\n', x_AC_wing);
fprintf('  S_H_NP    = VH×S×MAC/Lh     = %.3f m2\n', S_H_NP);
fprintf('  x_AC_tail = x_AC_wing + Lh  = %.3f m\n', x_AC_tail);
fprintf('  NP (formula) = %.4f m  |  NP (specified) = %.4f m\n', NP_formula, NP);
fprintf('  MAC  = %.4f m\n', MAC);
fprintf('  %-14s  CG=%8.4f m   SM=%+.2f%% MAC   %s\n', ...
        'MTOW', CG_MTOW, SM_MTOW, pf(SM_MTOW-5));
fprintf('  %-14s  CG=%8.4f m   SM=%+.2f%% MAC   %s\n', ...
        'ZFW',  CG_ZFW,  SM_ZFW,  pf(SM_ZFW-5));
fprintf('  %-14s  CG=%8.4f m   SM=%+.2f%% MAC   %s\n', ...
        'OEW',  x_OEW,   SM_OEW,  pf(SM_OEW-5));

fprintf('\n--- BELLY TANK (Section 4) ---------------------------------------\n');
fprintf('  %-32s %10.4f  %s\n','Cross-section area A_seg', A_seg,         'm2');
fprintf('  %-32s %10.4f  %s\n','Tank fwd bulkhead',        x_tank_fwd,    'm');
fprintf('  %-32s %10.4f  %s\n','Tank aft bulkhead',        x_tank_aft,    'm');
fprintf('  %-32s %10.2f  %s\n','Tank length L_tank',       L_tank,        'm');
fprintf('  %-32s %10.4f  %s\n','Volume available',         tank_vol_fus,  'm3');
fprintf('  %-32s %10.2f  %s\n','Volume required',          V_reqd,        'm3');
fprintf('  %-32s %10.1f  %s\n','Fill fraction',            tank_fill_pct, '%');

fprintf('\n--- FUSELAGE STRUCTURAL (Section 6) -----------------------------\n');
fprintf('  %-32s %10.2f  %s\n','Slenderness L/D',   SR,            '-');
fprintf('  %-32s %10.2f  %s\n','Cabin dP',          dP/1000,       'kPa');
fprintf('  %-32s %10.2f  %s\n','Hoop stress',       sig_hoop/1e6,  'MPa');
fprintf('  %-32s %10.2f  %s\n','Safety factor hoop',SF_hoop,       '-');
fprintf('  %-32s %10.2f  %s\n','Max BM at 2.5g',    BM_max/1e6,    'MN.m');

fprintf('\n--- WING STRUCTURAL (WingStructuralAnalysis) --------------------\n');
fprintf('  Span=%.1fm  KinkPos=%dm  WingPos=%.2fm  b_half=%.1fm\n', ...
        ADP_Span,ADP_KinkPos,ADP_WingPos,b_half_ws);
fprintf('  n_limit=%.1fg  n_ult=%.2fg\n', ws_n_limit, ws_n_ult);
fprintf('  %-32s %10.2f  %s\n','Root BM (ult)',     ws_M_root_ult/1e6,   'MN.m');
fprintf('  %-32s %10.2f  %s\n','Root shear (ult)',  ws_V_root_ult/1e6,   'MN');
fprintf('  %-32s %10.0f  %s\n','Box height (root)', h_box_root_ws*1e3,   'mm');
fprintf('  %-32s %10.2f  %s  (%d plies)\n','Spar cap thickness', t_cap_ws*1e3,'mm',n_plies_cap_ws);
fprintf('  %-32s %10.2f  %s  (%d plies)\n','Web thickness',      t_web_ws*1e3,'mm',n_plies_web_ws);
fprintf('  %-32s %10.2f  %s  (%d plies)\n','Skin thickness',     t_skin_ws*1e3,'mm',n_plies_skin_ws);
fprintf('  %-32s %10d\n',       'Ribs per semi-span', n_ribs_half_ws);
fprintf('  %-32s %10.0f  %s\n','Spar caps',    ws_m_spar_cap, 'kg');
fprintf('  %-32s %10.0f  %s\n','Web',          ws_m_web,      'kg');
fprintf('  %-32s %10.0f  %s\n','Skin',         ws_m_skin,     'kg');
fprintf('  %-32s %10.0f  %s\n','Ribs',         ws_m_ribs,     'kg');
fprintf('  %-32s %10.0f  %s\n','Secondary',    ws_m_secondary,'kg');
fprintf('  %-32s %10.0f  %s\n','TOTAL wing',   ws_m_total,    'kg');
fprintf('  MS bending: %+.3f  %s    MS shear: %+.3f  %s\n', ...
        ws_MS_bending,pf(ws_MS_bending), ws_MS_shear,pf(ws_MS_shear));

fprintf('\n--- MASS BUDGET --------------------------------------------------\n');
fprintf('  %-20s  %8s  %8s  %8s\n','Component','Class I','Class II','Cls II.5');
fprintf('  %s\n',repmat('-',1,52));
cn  = {'Wing','Fuselage','HTP','VTP','Gear','Propulsion','Systems'};
c1  = [CI_W_wing, CI_W_fus, CI_W_ht, CI_W_vt, CI_W_lg, CI_W_prop, CI_W_sys]/1e3;
c2  = [CII_W_wing,CII_W_fus,CII_W_ht,CII_W_vt,CII_W_lg,CII_W_prop,CII_W_sys]/1e3;
c25 = [CII5_W_wing,CII5_W_fus,CII5_W_ht,CII5_W_vt,CII5_W_lg,CII5_W_prop,CII5_W_sys]/1e3;
for k = 1:7
    fprintf('  %-20s  %8.1f  %8.1f  %8.1f  t\n',cn{k},c1(k),c2(k),c25(k));
end
fprintf('  %s\n',repmat('-',1,52));
fprintf('  %-20s  %8.1f  %8.1f  %8.1f  t\n','OEW (target 200t)', ...
        CI_OEW/1e3, CII_OEW_tot/1e3, CII5_OEW_tot/1e3);
fprintf('  %-20s  %8s  %+7.1f%%  %+7.1f%%\n','Error vs 200t','-', ...
        (CII_OEW_tot-OEW)/OEW*100, (CII5_OEW_tot-OEW)/OEW*100);

fprintf('\n--- STABILITY SIGN-OFF (verbatim from fuselage file) ------------\n');
fprintf('  SM @ OEW  = %+.2f%% MAC  [%s]\n',SM_OEW,  ternary(SM_OEW>5,'STABLE [OK]','CHECK [FAIL]'));
fprintf('  SM @ ZFW  = %+.2f%% MAC  [%s]\n',SM_ZFW,  ternary(SM_ZFW>5,'STABLE [OK]','CHECK [FAIL]'));
fprintf('  SM @ MTOW = %+.2f%% MAC  [%s]\n',SM_MTOW, ternary(SM_MTOW>5,'STABLE [OK]','CHECK [FAIL]'));
fprintf('  Belly tank: %.2fm → %.2fm  CG=%.1fm  Vol=%.1fm3  Fill=%.1f%%\n', ...
        x_tank_fwd,x_tank_aft,x_fb,tank_vol_fus,tank_fill_pct);
fprintf('  8 figures generated.\n');
fprintf('=================================================================\n\n');

%% =========================================================================
%  BLOCK 10  :  FIGURES
% =========================================================================

%% -----------------------------------------------------------------------
%  FIGURE 1  :  OEW Component Breakdown  (Class I / II / II.5)
% -----------------------------------------------------------------------
figure('Name','Fig 1 — OEW Breakdown','NumberTitle','off', ...
       'Color','w','Position',[40 580 940 460]);
labels = {'Wing','Fuselage','HTP','VTP','Gear','Propulsion','Systems'};
X  = reordercats(categorical(labels),labels);
bh = bar(X,[c1;c2;c25]','grouped');
bh(1).FaceColor=[0.22 0.48 0.82];
bh(2).FaceColor=[0.90 0.50 0.10];
bh(3).FaceColor=[0.18 0.70 0.38];
yline(OEW/1e3,'r--','LineWidth',2,'Label',sprintf('Target OEW=%.0ft',OEW/1e3));
ylabel('Mass  [t]','FontSize',11);
title('OEW Component Breakdown  —  Class I / II / II.5','FontSize',12,'FontWeight','bold');
legend({'Class I','Class II','Class II.5'},'Location','northeast','FontSize',10);
grid on;  set(gca,'FontSize',10,'GridAlpha',0.20);

%% -----------------------------------------------------------------------
%  FIGURE 2  :  CG Potato Diagram  (style: fuselage Fig 8)
%  Two loading sequences; NP and CG limits plotted
% -----------------------------------------------------------------------
figure('Name','Fig 2 — CG Envelope','NumberTitle','off', ...
       'Color','w','Position',[40 80 820 520]);
hold on;

% CG envelope band (15%–40% MAC, fuselage Fig 8 style)
cg_fwd = LEMAC + 0.15*MAC;  cg_aft = LEMAC + 0.40*MAC;
fill([cg_fwd,cg_aft,cg_aft,cg_fwd,cg_fwd],[OEW,OEW,MTOW,MTOW,OEW]/1e3, ...
     [0.80 0.90 0.98],'EdgeColor',[0.20 0.40 0.75],'LineWidth',1.5,'FaceAlpha',0.50);
text(mean([cg_fwd,cg_aft]),mean([OEW,MTOW])/1e3,'CG Envelope', ...
     'HorizontalAlignment','center','FontSize',9,'Color',[0.15 0.35 0.65],'FontWeight','bold');

% Sequence A: OEW → payload → belly fuel → wing fuel
W_A=[OEW, OEW+Payload*0.5, OEW+Payload, ...
     OEW+Payload+Fuel_fus*0.5, OEW+Payload+Fuel_fus, ...
     OEW+Payload+Fuel_fus+Fuel_wing, MTOW]/1e3;
m0=OEW*x_OEW;
M_A=[m0, m0+0.5*Payload*x_payload, m0+Payload*x_payload, ...
     m0+Payload*x_payload+0.5*Fuel_fus*x_fb, ...
     m0+Payload*x_payload+Fuel_fus*x_fb, ...
     m0+Payload*x_payload+Fuel_fus*x_fb+Fuel_wing*x_fw, ...
     m0+Payload*x_payload+Fuel_fus*x_fb+2*Fuel_wing*x_fw];
cg_A = M_A ./ (W_A*1e3);

% Sequence B: OEW → wing fuel → belly fuel → payload
W_B=[OEW, OEW+Fuel_wing, OEW+2*Fuel_wing, OEW+2*Fuel_wing+Fuel_fus, ...
     OEW+Fuel, OEW+Fuel+Payload*0.5, MTOW]/1e3;
M_B=[m0, m0+Fuel_wing*x_fw, m0+2*Fuel_wing*x_fw, ...
     m0+2*Fuel_wing*x_fw+Fuel_fus*x_fb, ...
     m0+2*Fuel_wing*x_fw+Fuel_fus*x_fb, ...
     m0+2*Fuel_wing*x_fw+Fuel_fus*x_fb+0.5*Payload*x_payload, ...
     m0+2*Fuel_wing*x_fw+Fuel_fus*x_fb+Payload*x_payload];
cg_B = M_B ./ (W_B*1e3);

plot(cg_A,W_A,'b-o','LineWidth',2,'DisplayName','Payload \rightarrow Fuel');
plot(cg_B,W_B,'r-s','LineWidth',2,'DisplayName','Fuel \rightarrow Payload');
xline(NP,       'k--','LineWidth',2,  'Label',sprintf('NP=%.2fm',NP));
xline(cg_fwd,   'r--','LineWidth',1.5,'Label','Fwd limit');
xline(cg_aft,   'r--','LineWidth',1.5,'Label','Aft limit');

% Key points (fuselage Fig 8 style)
plot(x_OEW,  OEW/1e3,        'o','MarkerSize',10,'MarkerFaceColor',[0.82 0.22 0.22],'MarkerEdgeColor','k');
plot(CG_ZFW, (OEW+Payload)/1e3,'o','MarkerSize',10,'MarkerFaceColor',[0.18 0.72 0.38],'MarkerEdgeColor','k');
plot(CG_MTOW,MTOW/1e3,        'o','MarkerSize',10,'MarkerFaceColor',[0 0 0],          'MarkerEdgeColor','k');
text(x_OEW+0.2,  OEW/1e3+8,         sprintf('CG_{OEW}=%.2fm',x_OEW),  'FontSize',8,'Color',[0.82 0.22 0.22],'FontWeight','bold');
text(CG_ZFW+0.2, (OEW+Payload)/1e3+8,sprintf('CG_{ZFW}=%.2fm',CG_ZFW),'FontSize',8,'Color',[0.18 0.72 0.38],'FontWeight','bold');
text(CG_MTOW+0.2,MTOW/1e3+8,         sprintf('CG_{MTOW}=%.2fm',CG_MTOW),'FontSize',8,'Color','k','FontWeight','bold');

% SM annotation (fuselage Fig 8 style)
ann_y = MTOW*0.965/1e3;
plot([CG_MTOW NP],[ann_y ann_y],'k-','LineWidth',1.2);
plot([CG_MTOW CG_MTOW],[ann_y-3 ann_y+3],'k-','LineWidth',1.2);
plot([NP NP],[ann_y-3 ann_y+3],'k-','LineWidth',1.2);
text(mean([CG_MTOW,NP]),ann_y-12,sprintf('SM=%.1f%% MAC',SM_MTOW), ...
     'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');

xlabel('CG station  x  [m from nose]','FontSize',11);
ylabel('Aircraft mass  [t]','FontSize',11);
title(sprintf('CG ENVELOPE  |  SM@MTOW=%.1f%%  SM@ZFW=%.1f%%  SM@OEW=%.1f%%  — ALL STABLE', ...
      SM_MTOW,SM_ZFW,SM_OEW),'FontSize',12,'FontWeight','bold');
legend('Location','southeast','FontSize',9);
grid on;  set(gca,'FontSize',10,'GridAlpha',0.20);
hold off;

%% -----------------------------------------------------------------------
%  FIGURE 3  :  CG Migration During Fuel Burn  (belly-first)
% -----------------------------------------------------------------------
figure('Name','Fig 3 — CG During Fuel Burn','NumberTitle','off', ...
       'Color','w','Position',[980 580 760 460]);
hold on;
fb_pct  = linspace(0,100,150);
cg_burn = arrayfun(@(f) burn_cg(f/100*Fuel, Fuel_fus, 2*Fuel_wing, ...
    OEW,Payload,x_OEW,x_payload,x_fb,x_fw), fb_pct);

plot(fb_pct,cg_burn,'b-','LineWidth',2.5);
xline(Fuel_fus/Fuel*100,'r--','LineWidth',1.5,'Label','Belly tank empty');
yline(NP,       'k--','LineWidth',1.5,'Label',sprintf('NP=%.2fm',NP));
yline(cg_fwd,   'r--','LineWidth',1.2,'Label','Fwd CG limit');
yline(cg_aft,   'g--','LineWidth',1.2,'Label','Aft CG limit');
xlabel('Fuel Burned  [% of total]','FontSize',11);
ylabel('CG Position  [m from nose]','FontSize',11);
title('CG Migration  —  Belly-First Burn Strategy','FontSize',12,'FontWeight','bold');
grid on;  set(gca,'FontSize',10,'GridAlpha',0.20);
hold off;

%% -----------------------------------------------------------------------
%  FIGURE 4  :  Static Margin Sensitivity to HTP Area
% -----------------------------------------------------------------------
figure('Name','Fig 4 — SM vs HTP Area','NumberTitle','off', ...
       'Color','w','Position',[980 80 760 460]);
hold on;
S_ht_sw = linspace(40,300,100);
%  NP varies with S_H using fuselage file formula: NP=(x_AC_w*S + x_AC_t*S_H)/(S+S_H)
NP_sw   = arrayfun(@(sh) (x_AC_wing*S_wing + x_AC_tail*sh)/(S_wing+sh), S_ht_sw);
SM_sw   = (NP_sw - CG_MTOW)/MAC*100;

plot(S_ht_sw,SM_sw,'b-','LineWidth',2.5);
xline(S_H,'r--','LineWidth',2,'Label',sprintf('S_H=%.1fm²',S_H));
yline(5, 'g--','LineWidth',1.5,'Label','SM_{min}=5%');
yline(35,'m--','LineWidth',1.5,'Label','SM_{max}=35%');
plot(S_H,SM_MTOW,'kp','MarkerSize',13,'MarkerFaceColor','y');
xlabel('Horizontal Tail Area  S_H  [m²]','FontSize',11);
ylabel('Static Margin at MTOW  [% MAC]','FontSize',11);
title('Static Margin Sensitivity to HTP Area','FontSize',12,'FontWeight','bold');
grid on;  set(gca,'FontSize',10,'GridAlpha',0.20);
hold off;

%% -----------------------------------------------------------------------
%  FIGURE 5  :  CG & NP on Fuselage Side Profile
%  Style mirrors fuselage_final_1_m.txt Figures 1 & 8
% -----------------------------------------------------------------------
figure('Name','Fig 5 — CG & NP on Profile','NumberTitle','off', ...
       'Color','w','Position',[40 80 1120 420]);
hold on;

fill([xp,fliplr(xp)],[rp,-fliplr(rp)],[0.67 0.80 0.93], ...
     'EdgeColor',[0.18 0.42 0.72],'LineWidth',1.8,'FaceAlpha',0.72);
plot([0 L_fus],[0 0],'--','Color',[0.70 0.70 0.70],'LineWidth',0.8);

% Belly tank (fuselage Fig 1 style)
fill([x_tank_fwd,x_tank_aft,x_tank_aft,x_tank_fwd], ...
     [keel_y+0.05,keel_y+0.05,belly_top,belly_top], ...
     [0.12 0.55 0.92],'FaceAlpha',0.72,'EdgeColor',[0.04 0.28 0.72],'LineWidth',2.0);
text((x_tank_fwd+x_tank_aft)/2,(keel_y+belly_top)/2+0.15, ...
     sprintf('BELLY TANK  %.0fkg|arm=%.1fm|L=%.0fm', Fuel_fus,x_fb,L_tank), ...
     'HorizontalAlignment','center','FontSize',8,'Color',[0.02 0.18 0.55],'FontWeight','bold');

% Wing (fuselage Fig 1 style)
wx1=wx0+Cr; wx2=wx1+SW*9+Ct; wx3=wx0+SW*9; wyt=R_fus+1.9;
fill([wx0,wx1,wx2,wx3],[R_fus,R_fus,wyt,wyt],[0.30 0.55 0.90], ...
     'FaceAlpha',0.50,'EdgeColor',[0.15 0.35 0.75],'LineWidth',1.5);
fill([wx0,wx1,wx2,wx3],-[R_fus,R_fus,wyt,wyt],[0.30 0.55 0.90], ...
     'FaceAlpha',0.50,'EdgeColor',[0.15 0.35 0.75],'LineWidth',1.5);

% HTP
hy0=R_fus*0.72; hy1=hy0+1.3;
fill([hx0,hx0+7.2,hx0+9.8,hx0+0.8],[hy0,hy0,hy1,hy1],[0.95 0.72 0.18], ...
     'FaceAlpha',0.65,'EdgeColor',[0.72 0.48 0.05],'LineWidth',1.5);
fill([hx0,hx0+7.2,hx0+9.8,hx0+0.8],-[hy0,hy0,hy1,hy1],[0.95 0.72 0.18], ...
     'FaceAlpha',0.65,'EdgeColor',[0.72 0.48 0.05],'LineWidth',1.5);

% VTP (fuselage Fig 1 style — root ON fuselage top skin)
fill([VT_LE_root_x,VT_TE_root_x,VT_TE_tip_x,VT_LE_tip_x], ...
     [VT_root_y,VT_root_y,VT_tip_y,VT_tip_y], ...
     [0.15 0.75 0.35],'FaceAlpha',0.65,'EdgeColor',[0.08 0.52 0.18],'LineWidth',1.8);

% LEMAC line (fuselage Fig 1 style)
plot([LEMAC LEMAC],[-(R_fus+0.5) R_fus+0.5],'m-','LineWidth',1.5);
text(LEMAC,R_fus+0.75,sprintf('LEMAC\n%.1fm',LEMAC),'FontSize',7.5,'Color',[0.55 0 0.55], ...
     'HorizontalAlignment','center','FontWeight','bold');

% CG envelope band
fill([cg_fwd cg_aft cg_aft cg_fwd],[-R_fus*0.45 -R_fus*0.45 R_fus*0.45 R_fus*0.45], ...
     [0.80 0.90 0.98],'FaceAlpha',0.45,'EdgeColor',[0.20 0.40 0.75],'LineWidth',1.5);

% Key markers (fuselage Fig 1 style)
plot(CG_MTOW,0,'rv','MarkerSize',12,'MarkerFaceColor','r');
text(CG_MTOW,-R_fus*0.30,sprintf('CG_{MTOW}\n%.2fm',CG_MTOW), ...
     'FontSize',8,'Color','r','HorizontalAlignment','center','FontWeight','bold');
plot(x_OEW,0,'rs','MarkerSize',9,'MarkerFaceColor',[1.0 0.5 0.5]);
text(x_OEW,R_fus*0.22,sprintf('CG_{OEW}\n%.1fm',x_OEW), ...
     'FontSize',7.5,'Color',[0.75 0.05 0.05],'HorizontalAlignment','center');
plot(NP,0,'bs','MarkerSize',10,'MarkerFaceColor','b');
text(NP,R_fus*0.62,sprintf('NP\n%.2fm',NP), ...
     'FontSize',8,'Color',[0.10 0.20 0.72],'HorizontalAlignment','center','FontWeight','bold');
plot(x_fb,keel_y+0.08,'b^','MarkerSize',8,'MarkerFaceColor',[0.12 0.55 0.92]);
text(x_fb,keel_y-0.28,sprintf('x_{fb}=%.1fm',x_fb), ...
     'FontSize',7.5,'Color',[0.04 0.28 0.72],'HorizontalAlignment','center');

% Length arrow
ay=-(R_fus+3.5);
plot([0 L_fus],[ay ay],'k-','LineWidth',1.2);
plot([0 0],[ay-0.28 ay+0.28],'k-','LineWidth',1.2);
plot([L_fus L_fus],[ay-0.28 ay+0.28],'k-','LineWidth',1.2);
text(L_fus/2,ay-0.80,sprintf('L_{fus}=%.1fm',L_fus), ...
     'HorizontalAlignment','center','FontSize',10,'FontWeight','bold');

axis equal;  grid on;
xlim([-7 L_fus+8]);  ylim([-(R_fus+5) R_fus+VT_height+3]);
xlabel('Fuselage station x (m from nose)','FontSize',11);
ylabel('Radius / Height (m)','FontSize',11);
title(sprintf('SIDE PROFILE  |  CG_{MTOW}=%.2fm  SM@MTOW=%.1f%%  NP=%.2fm  |  Tank L=%.0fm arm=%.1fm', ...
      CG_MTOW,SM_MTOW,NP,L_tank,x_fb),'FontSize',10,'FontWeight','bold');
set(gca,'FontSize',10,'GridAlpha',0.18);
hold off;

%% -----------------------------------------------------------------------
%  FIGURE 6  :  OEW Mass Pie Chart  (Class II.5)
% -----------------------------------------------------------------------
figure('Name','Fig 6 — OEW Pie (II.5)','NumberTitle','off', ...
       'Color','w','Position',[40 80 920 480]);
pie_v=[CII5_W_wing,CII5_W_fus,CII5_W_ht+CII5_W_vt, ...
       CII5_W_lg,CII5_W_prop,CII5_W_sys+CII5_W_fsys, ...
       CII5_W_oper,CII5_ballast];
pie_l={sprintf('Wing\n%.0fkg',CII5_W_wing), ...
       sprintf('Fuselage\n%.0fkg',CII5_W_fus), ...
       sprintf('Tail\n%.0fkg',CII5_W_ht+CII5_W_vt), ...
       sprintf('Gear\n%.0fkg',CII5_W_lg), ...
       sprintf('Propulsion\n%.0fkg',CII5_W_prop), ...
       sprintf('Systems\n%.0fkg',CII5_W_sys+CII5_W_fsys), ...
       sprintf('Operators\n%.0fkg',CII5_W_oper), ...
       sprintf('Ballast\n%.0fkg',CII5_ballast)};
pie(pie_v,pie_l);
title(sprintf('OEW Mass Breakdown  (Class II.5)  |  Total=%.0ft  (%.1f%% MTOW)', ...
      CII5_OEW_tot/1e3,CII5_OEW_tot/MTOW*100),'FontSize',12,'FontWeight','bold');
colormap(parula(8));

%% -----------------------------------------------------------------------
%  FIGURE 7  :  Empennage Sizing Trades  (fuselage file VH/VV/Lh/Lv values)
% -----------------------------------------------------------------------
figure('Name','Fig 7 — Empennage Trades','NumberTitle','off', ...
       'Color','w','Position',[980 80 840 460]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

nexttile;
Lh_sw=linspace(20,55,80);
S_H_sw=VH*S_wing*MAC./Lh_sw;
plot(Lh_sw,S_H_sw,'b-','LineWidth',2.5);  hold on;
plot(Lh,S_H,'rp','MarkerSize',14,'MarkerFaceColor','r', ...
     'DisplayName',sprintf('Design  L_h=%.1fm, S_H=%.1fm²',Lh,S_H));
xlabel('HTP Moment Arm  L_h  [m]','FontSize',11);
ylabel('HTP Area  S_H  [m²]','FontSize',11);
title(sprintf('HTP Sizing  |  V_H=%.2f (specified)',VH),'FontSize',11,'FontWeight','bold');
legend('Location','northeast','FontSize',9);  grid on;

nexttile;
Lv_sw=linspace(20,55,80);
S_V_sw=VV*S_wing*b_wing./Lv_sw;
plot(Lv_sw,S_V_sw,'r-','LineWidth',2.5);  hold on;
plot(Lv,S_V,'bp','MarkerSize',14,'MarkerFaceColor','b', ...
     'DisplayName',sprintf('Design  L_v=%.1fm, S_V=%.1fm²',Lv,S_V));
xlabel('VTP Moment Arm  L_v  [m]','FontSize',11);
ylabel('VTP Area  S_V  [m²]','FontSize',11);
title(sprintf('VTP Sizing  |  V_V=%.2f (specified)',VV),'FontSize',11,'FontWeight','bold');
legend('Location','northeast','FontSize',9);  grid on;

%% -----------------------------------------------------------------------
%  FIGURE 8  :  Wing Structural Load Distributions
%  Style matches WingStructuralAnalysis (2).m tiles 2, 3, 4
% -----------------------------------------------------------------------
figure('Name','Fig 8 — Wing Structural Distributions','NumberTitle','off', ...
       'Color','w','Position',[40 80 1180 440]);
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
sgtitle(sprintf('Wing Structural Loads  |  MTOW=%.0ft  n_{ult}=%.2fg  Span=%.1fm  CFRP IM7/8552', ...
    MTOW/1e3,ws_n_ult,ADP_Span),'FontSize',11,'FontWeight','bold');

nexttile;  % Tile 2: BM distribution
hold on;  grid on;
plot(y_s_ws, M_dist_ws/1e6,'r-','LineWidth',2.5);
xline(y_eng1,'k--','LineWidth',1.5,'Label',sprintf('35%% span (%.1fm)',y_eng1),'LabelVerticalAlignment','bottom');
xline(y_eng2,'b--','LineWidth',1.5,'Label',sprintf('70%% span (%.1fm)',y_eng2),'LabelVerticalAlignment','bottom');
xlabel('Semi-span y (m)','FontSize',10);
ylabel('Bending Moment (MN·m)','FontSize',10);
title(sprintf('Ultimate BM  (n_{ult}=%.2fg)',ws_n_ult),'FontSize',10,'FontWeight','bold');
xlim([0 b_half_ws]);  box on;
text(0.05*b_half_ws,0.90*max(M_dist_ws/1e6), ...
     sprintf('M_{root}=%.1f MN·m',ws_M_root_ult/1e6),'FontSize',9,'Color','r');

nexttile;  % Tile 3: SF distribution
hold on;  grid on;
plot(y_s_ws, V_dist_ws/1e6,'g-','LineWidth',2.5);
xline(y_eng1,'k--','LineWidth',1.5);
xline(y_eng2,'b--','LineWidth',1.5);
xlabel('Semi-span y (m)','FontSize',10);
ylabel('Shear Force (MN)','FontSize',10);
title(sprintf('Ultimate Shear Force  (n_{ult}=%.2fg)',ws_n_ult),'FontSize',10,'FontWeight','bold');
xlim([0 b_half_ws]);  box on;

nexttile;  % Tile 4: Spar cap area distribution
hold on;  grid on;
plot(y_s_ws, A_cap_dist_ws*1e4,'m-','LineWidth',2.5);
xline(y_eng1,'k--','LineWidth',1.5);
xline(y_eng2,'b--','LineWidth',1.5);
xlabel('Semi-span y (m)','FontSize',10);
ylabel('Spar Cap Area (cm²)','FontSize',10);
title('Required Spar Cap Area (each flange)','FontSize',10,'FontWeight','bold');
xlim([0 b_half_ws]);  box on;
text(0.05*b_half_ws,0.90*max(A_cap_dist_ws*1e4), ...
     sprintf('Root: %.1f cm²',A_cap_root_ws*1e4),'FontSize',9,'Color','m');

%% =========================================================================
%  LOCAL HELPER FUNCTIONS
% =========================================================================

function s = pf(margin)
    if margin >= 0,  s = 'PASS';  else,  s = 'FAIL';  end
end

function s = ternary(cond, a, b)
    if cond,  s = a;  else,  s = b;  end
end

function cg = burn_cg(burned, W_belly, W_wing_tot, ...
    Woew, Wpay, Xoew, Xpay, Xbelly, Xwing)
% Belly-first burn: belly depletes before wing tanks
    belly  = max(0, W_belly    - burned);
    wing   = max(0, W_wing_tot - max(0, burned - W_belly));
    W_tot  = Woew + Wpay + belly + wing;
    mom    = Xoew*Woew + Xpay*Wpay + Xbelly*belly + Xwing*wing;
    cg     = mom / W_tot;
end
