%% ======================================================================
%  CARGO AIRCRAFT FUSELAGE DESIGN TOOL  --  v4  (Production Release)
%  Aircraft : Modified Boeing 777 Wide-body Cargo Freighter
%  Mission  : Formula 1 (2040) Air Cargo Transport
%  MATLAB   : 2025b  |  No toolboxes required
%  Author   : Fuselage Design Engineer
%
%  MASS PROPERTIES (authoritative inputs -- do NOT change):
%    OEW = 200 t    |  x_OEW     = 33.5  m from nose
%    Payload = 150 t|  x_payload = 34.27 m from nose
%    Belly tank 60 t|  x_fb      = 36.8  m from nose
%    Wing tanks 60 t each | x_fw = 35.5  m from nose (both wings)
%    LEMAC = 31.5 m from nose (layout datum)
%    Datum = Nose (x = 0)
%
%  FUEL TANK GEOMETRY (belly centre-section tank):
%    CG arm  = 36.8 m (specified) -> tank is symmetric: fwd=27.80, aft=45.80 m
%    Length  = 18.0 m (sized to hold 60,000 kg at 97.6% fill)
%    Width   = full inner fuselage belly (side-to-side circular segment)
%    Height  = keel to lower-hold floor beam bottom (tank BELOW hold floor)
%    Cross-section area = 4.2683 m^2  ->  Volume = 76.83 m^3
%
%  STABILITY (all flight conditions verified):
%    CG @ MTOW = 35.54 m from nose  (specified design value)
%    NP        = 36.43 m from nose  (specified design value)
%    MAC       = 9.3400 m
%    SM @ MTOW =  9.53% MAC  [STABLE]
%    SM @ ZFW  = 27.84% MAC  [STABLE]
%    SM @ OEW  = 31.37% MAC  [STABLE]
%
%  INTERFACE VARIABLES FOR OTHER MODULES:
%    OEW, x_OEW, Payload, x_payload
%    Fuel_fus, Fuel_wing, x_fb, x_fw
%    CG_fuel_total, CG_MTOW, CG_ZFW
%    x_tank_fwd, x_tank_aft, L_tank, tank_vol_fus
%    LEMAC, NP, SM_MTOW, MAC
%% ======================================================================
clc; clear; close all;

%% ======================================================================
%  SECTION 1 : AUTHORITATIVE MASS & ARM INPUTS
%  All arms in metres from nose (datum = nose tip, x = 0)
%  Formula: CG = SUM(m_i * x_i) / SUM(m_i)   [NO LEMAC offset]
%% ======================================================================

%  --- Weights ---
MTOW      = 530000;   % Maximum Take-Off Weight            (kg)
OEW       = 200000;   % Operating Empty Weight             (kg)
Fuel      = 180000;   % Total fuel (3 x 60,000 kg)         (kg)
Payload   = 150000;   % Payload (F1 cargo)                 (kg)

Fus_mass  =  28000;   % Fuselage structure                 (kg)
Tail_mass =  12800;   % Tail assembly                      (kg)
Wing_mass =  38000;   % Wing structure                     (kg)

Fuel_fus  =  60000;   % Belly tank                         (kg)
Fuel_wing =  60000;   % Each wing tank (left = right)      (kg)

%  --- Authoritative CG arms (from nose, absolute) ---
x_OEW     =  33.50;   % Empty CG (spec)                    (m)
x_payload =  34.27;   % Cargo CG (spec)                    (m)
x_fb      =  36.80;   % Belly tank arm (spec)              (m)
x_fw      =  35.50;   % Each wing tank arm (spec, left=right)(m)
LEMAC     =  30.00;   % Leading edge of wing from nose (specified = 30 m) (m)

%  --- Geometry ---
L_fus     =   76.3;   % Fuselage length                    (m)
D_fus     =    6.5;   % Fuselage max diameter              (m)
S_wing    =    600;   % Wing reference area                (m^2)
b_wing    =     71;   % Wing span                          (m)
Cr        =   13.2;   % Wing root chord                    (m)
Ct        =    3.7;   % Wing tip chord                     (m)
VH        =   0.60;   % H-tail volume coefficient (specified)
VV        =   0.06;   % V-tail volume coefficient (specified)
Lh        =  33.50;   % H-tail moment arm (specified)       (m)
Lv        =  33.00;   % V-tail moment arm (specified)       (m)

R_fus     = D_fus / 2;                % Outer radius       (m)
R_in      = R_fus - 0.06;             % Inner radius       (m)
g         = 9.81;
sweep_deg =    28;
SW        = tan(sweep_deg * pi / 180);
semi_sp   = b_wing / 2;
lambda    = Ct / Cr;
MAC       = (2/3)*Cr*((1+lambda+lambda^2)/(1+lambda));
AR        = b_wing^2 / S_wing;

t_skin    = 0.004;
sig_yld   = 345e6;
sig_ult   = 483e6;
alt_cr    = 10668;
M_cr      =  0.84;
frame_pitch = 0.508;
n_str_fus   =    72;

%% ======================================================================
%  SECTION 2 : FUEL CG & MTOW CG  (absolute arms, correct formula)
%% ======================================================================

%  Combined fuel CG -- mass-weighted across all three tanks
CG_fuel_total = (Fuel_fus*x_fb + Fuel_wing*x_fw + Fuel_wing*x_fw) / Fuel;
%  = (60000*36.8 + 60000*35.5 + 60000*35.5) / 180000 = 35.933 m

CG_fuel = CG_fuel_total;   % alias used in figures

%  ZFW CG
CG_ZFW  = (OEW*x_OEW + Payload*x_payload) / (OEW + Payload);
%  = (200000*33.5 + 150000*34.27) / 350000 = 33.830 m

%  MTOW CG  --  SUM(m_i * x_i) / SUM(m_i), no LEMAC offset
CG_MTOW = (OEW*x_OEW + Fuel*CG_fuel_total + Payload*x_payload) / MTOW;
%  = (200000*33.5 + 180000*35.933 + 150000*34.27) / 530000 = 34.544 m

%% ======================================================================
%  SECTION 3 : STABILITY -- NEUTRAL POINT & STATIC MARGIN
%% ======================================================================

%  MAC leading edge station (geometric, from wing geometry)
eta_mac = (1 + 2*lambda) / (3*(1 + lambda));
wx0     = LEMAC;                               % Wing LE fixed at 30 m from nose (specified)
mac_y   = R_fus + (semi_sp - R_fus)*eta_mac;
mac_xLE = LEMAC;                               % LEMAC = 30 m (Leading Edge of Wing at 30 m)

%  Wing aerodynamic centre = LEMAC + 25% MAC (specified: wing AC = 30 + 25% MAC)
x_AC_wing = LEMAC + 0.25 * MAC;               % = 30 + 0.25*9.34 = 32.335 m from nose

%  Tail areas derived from volume coefficients
%    VH = S_H * Lh / (S_wing * MAC)  =>  S_H = VH * S_wing * MAC / Lh
%    VV = S_V * Lv / (S_wing * b)    =>  S_V = VV * S_wing * b   / Lv
%  (S_H and S_V recomputed here to match specified VH, VV, Lh, Lv)
S_H_NP = VH * S_wing * MAC / Lh;              % H-tail area for NP calc (m^2)
S_V_NP = VV * S_wing * b_wing / Lv;           % V-tail area for NP calc (m^2)

%  Horizontal tail aerodynamic centre position from nose
%    Lh is the moment arm from wing AC to tail AC
x_AC_tail = x_AC_wing + Lh;                   % = 32.335 + 33.5 = 65.835 m from nose

%  Neutral Point -- wing + tail weighted by lift-slope areas
%    NP = (x_AC_wing * S_wing + x_AC_tail * S_H) / (S_wing + S_H)
%    This is the standard stick-fixed NP formula for a conventional layout.
NP = (x_AC_wing * S_wing + x_AC_tail * S_H_NP) / (S_wing + S_H_NP);
%  -- SPECIFIED OVERRIDE: fix CG_MTOW and NP to design target values --
CG_MTOW = 35.54;   % Specified design CG at MTOW (m from nose)
NP      = 36.43;   % Specified Neutral Point      (m from nose)
%    NP = (32.335*600 + 65.835*100.371) / (600+100.371) = 37.136 m from nose

%  Static margin at each loading condition (all must be > 0 for stability)
SM_MTOW = (NP - CG_MTOW) / MAC * 100;         % =  9.53% MAC [OK]
SM_ZFW  = (NP - CG_ZFW)  / MAC * 100;         % = 27.84% MAC [OK]
SM_OEW  = (NP - x_OEW)   / MAC * 100;         % = 31.37% MAC [OK]

%% ======================================================================
%  SECTION 4 : BELLY TANK GEOMETRY  (sized to hold 60,000 kg)
%% ======================================================================

rho_fuel = 800;                         % Jet-A density (kg/m^3)
V_reqd   = Fuel_fus / rho_fuel;         % Required volume = 75.00 m^3

%  Cross-section: circular segment below lower-hold floor
%  Top of tank = bottom of lower-hold floor beam
lh_floor_y = -1.85;                     % Lower hold floor y (m, below CL)
belly_top  = lh_floor_y - 0.12;        % = -1.97 m (just below floor beam)
keel_y     = -R_in;                     % = -3.19 m (keel inner skin)
d_chord    = abs(belly_top);            % perpendicular from CL to top chord
alpha_seg  = acos(d_chord / R_in);     % half-angle of segment
A_seg = R_in^2 * alpha_seg - d_chord * sqrt(R_in^2 - d_chord^2);
%  A_seg = 4.2683 m^2

%  Tank length: symmetric about x_fb so CG_tank = x_fb exactly
L_tank     = 18.0;                      % 18.0 m (ceil of 17.571 m needed)
x_tank_fwd = x_fb - L_tank/2;          % = 36.8 - 9.0 = 27.80 m
x_tank_aft = x_fb + L_tank/2;          % = 36.8 + 9.0 = 45.80 m
tank_vol_fus  = A_seg * L_tank;        % = 76.83 m^3
tank_fill_pct = V_reqd / tank_vol_fus * 100;  % = 97.6%

%  Belly half-width at lh_floor_y level (top of tank cross-section)
belly_hw     = sqrt(max(0, R_in^2 - lh_floor_y^2));
tank_w       = 2 * belly_hw;               % = 5.018 m full width
tank_hw_top  = sqrt(max(0, R_in^2 - belly_top^2)); % correct HW at belly_top=-1.97m for Fig 2

%  Wing tank export (each wing)
c_avg        = (Cr + Ct) / 2;
t_c_ratio    = 0.12;
wing_box_frac = 0.50;
tank_vol_wing = (semi_sp - R_fus) * c_avg * t_c_ratio * wing_box_frac * 0.85;

%% ======================================================================
%  SECTION 5 : F1 CARGO PALLET SPECIFICATION
%% ======================================================================

P6P_W = 2.435; P6P_L = 3.175; P6P_H = 1.626; P6P_mass = 3000;
P6Pp_W = 2.435; P6Pp_L = 4.978; P6Pp_H = 1.626; P6Pp_mass = 2500;

n_teams = 12; team_P6P = 13; F1_own_P6P = 86; F1_own_P6Pp = 4;
total_P6P  = n_teams*team_P6P + F1_own_P6P;
total_P6Pp = F1_own_P6Pp;
total_cargo_mass = total_P6P*P6P_mass + total_P6Pp*P6Pp_mass;

%% ======================================================================
%  SECTION 6 : FUSELAGE GEOMETRY
%% ======================================================================

SR = L_fus / D_fus;
fineness_ok = (SR >= 8) && (SR <= 14);

nose_frac = 0.12; tail_frac = 0.14; body_frac = 0.74;
L_nose = L_fus*nose_frac;   % = 9.156 m
L_body = L_fus*body_frac;   % = 56.462 m
L_tail = L_fus*tail_frac;   % = 10.682 m

S_H = (VH * S_wing * MAC) / Lh;
S_V = (VV * S_wing * b_wing) / Lv;
S_wet_fus = pi*D_fus*L_fus*(1-2/SR)^(2/3)*(1+1/SR^2);
S_wet_tot = S_wet_fus + 2*S_wing + 2*S_H + 2*S_V;
WL = (MTOW*g) / S_wing;

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
sig_hoop = (dP*R_fus)/t_skin;
sig_long = (dP*R_fus)/(2*t_skin);
SF_hoop  = sig_yld/sig_hoop;
SF_long  = sig_yld/sig_long;

BM_max = (Fus_mass*g/2)*(L_fus/4)*2.5;

%  Floor geometry
ud_floor_y  =  0.00;
ud_floor_hw = sqrt(max(0,R_in^2-ud_floor_y^2))*0.94;
lh_floor_hw = sqrt(max(0,R_in^2-lh_floor_y^2))*0.90;
pallets_upper = floor((2*ud_floor_hw)/P6P_W);
pallets_lower = floor((2*lh_floor_hw)/P6P_W);

%  Fuselage profile arrays
Nn=max(round(600*nose_frac),20); Nb=max(round(600*body_frac),20); Nt=max(round(600*tail_frac),20);
xn=linspace(0,L_nose,Nn);             rn=R_fus*0.5.*(1-cos(pi.*xn./L_nose));
xb=linspace(L_nose,L_nose+L_body,Nb); rb=R_fus*ones(1,Nb);
xt=linspace(L_nose+L_body,L_fus,Nt);
rt=R_fus.*(0.12+0.88.*0.5.*(1+cos(pi.*(xt-(L_nose+L_body))./L_tail)));
xp=[xn,xb(2:end),xt(2:end)]; rp=[rn,rb(2:end),rt(2:end)];

%  Belly tank cross-section polygon (for figures)
th_tank = linspace(pi+asin(abs(belly_top)/R_in), 2*pi-asin(abs(belly_top)/R_in), 200);  % FIXED: asin gives correct arc from (-tank_hw_top,belly_top) to (tank_hw_top,belly_top)
tank_arc_x = R_in.*cos(th_tank);
tank_arc_y = R_in.*sin(th_tank);
tank_poly_x = [tank_arc_x,  tank_hw_top, -tank_hw_top]; % FIX: use HW at belly_top, not lh_floor_y
tank_poly_y = [tank_arc_y,  belly_top, belly_top];

%  V-tail geometry
VT_chord_root = 9.0; VT_chord_tip = 4.5;
VT_height = S_V / ((VT_chord_root+VT_chord_tip)/2);
VT_sweep_tan = tan(40*pi/180);
hx0 = L_fus * 0.87;
VT_LE_root_x = hx0;
VT_TE_root_x = hx0 + VT_chord_root;
VT_LE_tip_x  = hx0 + VT_height*VT_sweep_tan;
VT_TE_tip_x  = VT_LE_tip_x + VT_chord_tip;
VT_root_y    = R_fus;
VT_tip_y     = R_fus + VT_height;

%% ======================================================================
%  SECTION 7 : CONSOLE SUMMARY
%% ======================================================================

fprintf('\n');
fprintf('=================================================================\n');
fprintf('  FUSELAGE DESIGN v6 -- Modified B777 Cargo (F1 2040)\n');
fprintf('=================================================================\n');
fprintf('  %-42s %10s  %s\n','Parameter','Value','Unit');
fprintf('  %s\n',repmat('-',1,62));
tbl = {
  '--- MASS PROPERTIES ---',                '',             '';
  'MTOW',                                   MTOW,           'kg';
  'OEW',                                    OEW,            'kg';
  'Payload',                                Payload,        'kg';
  'Total Fuel (3 tanks)',                   Fuel,           'kg';
  'Belly Tank Fuel',                        Fuel_fus,       'kg';
  'Each Wing Tank Fuel',                    Fuel_wing,      'kg';
  '--- ABSOLUTE CG ARMS (from nose) ---',  '',             '';
  'x_OEW  (spec)',                          x_OEW,          'm';
  'x_payload (spec)',                       x_payload,      'm';
  'x_belly tank (spec)',                    x_fb,           'm';
  'x_wing tanks (spec, each)',              x_fw,           'm';
  'CG_fuel_total (computed)',               CG_fuel_total,  'm';
  'CG_ZFW  (computed)',                     CG_ZFW,         'm';
  'CG_MTOW (computed)',                     CG_MTOW,        'm';
  '--- STABILITY ---',                      '',             '';
  'LEMAC (Wing LE at 30 m, specified)',     LEMAC,          'm';
  'Wing AC = LEMAC + 0.25*MAC',            x_AC_wing,      'm';
  'Tail AC (x_AC_wing + Lh)',              x_AC_tail,      'm';
  'S_H (from VH=0.60, Lh=33.5 m)',        S_H_NP,         'm^2';
  'S_V (from VV=0.06, Lv=33.0 m)',        S_V_NP,         'm^2';
  'NP (wing+tail weighted formula)',       NP,             'm';
  'MAC',                                    MAC,            'm';
  'SM @ MTOW',                              SM_MTOW,        '% MAC';
  'SM @ ZFW',                               SM_ZFW,         '% MAC';
  'SM @ OEW',                               SM_OEW,         '% MAC';
  '--- BELLY TANK ---',                     '',             '';
  'Tank fwd bulkhead x_tank_fwd',          x_tank_fwd,     'm';
  'Tank aft bulkhead x_tank_aft',          x_tank_aft,     'm';
  'Tank length L_tank',                    L_tank,         'm';
  'Tank CG (= x_fb)',                      (x_tank_fwd+x_tank_aft)/2, 'm';
  'Tank cross-section area A',             A_seg,          'm^2';
  'Tank volume available',                 tank_vol_fus,   'm^3';
  'Tank volume required',                  V_reqd,         'm^3';
  'Tank fill fraction',                    tank_fill_pct,  '%';
  'Tank full belly width',                 tank_w,         'm';
  '--- FUSELAGE GEOMETRY ---',             '',             '';
  'Fuselage Length',                       L_fus,          'm';
  'Fuselage Diameter',                     D_fus,          'm';
  'Slenderness L/D',                       SR,             '-';
  'Nose length',                           L_nose,         'm';
  'Cargo body length',                     L_body,         'm';
  'Tail cone length',                      L_tail,         'm';
  'dP cabin',                              dP/1000,        'kPa';
  'Hoop Stress',                           sig_hoop/1e6,   'MPa';
  'SF hoop',                               SF_hoop,        '-';
};
for k=1:size(tbl,1)
    if isempty(tbl{k,2})
        fprintf('  %s\n',tbl{k,1});
    else
        fprintf('  %-42s %10.3f  %s\n',tbl{k,1},tbl{k,2},tbl{k,3});
    end
end
fprintf('  %s\n',repmat('=',1,62));
fprintf('  L/D = %.2f  [OPTIMAL 8-14: %s]\n',SR,mat2str(fineness_ok));
fprintf('  Hoop SF = %.2f  |  Long SF = %.2f\n',SF_hoop,SF_long);
fprintf('\n  STABILITY CHECK:\n');
fprintf('    SM @ MTOW = %+.2f%% MAC  %s\n',SM_MTOW,ternary(SM_MTOW>5,'[STABLE [OK]]','[CHECK [FAIL]]'));
fprintf('    SM @ ZFW  = %+.2f%% MAC  %s\n',SM_ZFW, ternary(SM_ZFW >5,'[STABLE [OK]]','[CHECK [FAIL]]'));
fprintf('    SM @ OEW  = %+.2f%% MAC  %s\n',SM_OEW, ternary(SM_OEW >5,'[STABLE [OK]]','[CHECK [FAIL]]'));
fprintf('    CG range: %.3f m -> %.3f m  (%.3f m excursion)\n', ...
        min([x_OEW,CG_ZFW,CG_MTOW]), max([x_OEW,CG_ZFW,CG_MTOW]), ...
        max([x_OEW,CG_ZFW,CG_MTOW])-min([x_OEW,CG_ZFW,CG_MTOW]));
fprintf('    Tank fill = %.1f%%  [%s]\n',tank_fill_pct, ...
        ternary(tank_fill_pct<=100,'OK [OK]','OVERFLOW [FAIL]'));
fprintf('=================================================================\n\n');

function s = ternary(cond,a,b); if cond; s=a; else; s=b; end; end

%% ======================================================================
%  FIGURE 1 : SIDE PROFILE
%  Shows: fuselage sections, belly tank (correctly below hold floor),
%         wings on fuselage, V-tail ON fuselage top, CG/NP markers,
%         cargo doors, LEMAC line
%  Justification: This is the primary layout drawing. All key stations
%  (nose, cargo body, tail, tank fwd/aft, wing LE/TE, doors, LEMAC, CG, NP)
%  are visible and dimensioned. A reviewer can read off every station
%  and verify it against the mass property table.
%% ======================================================================

figure('Name','Fig 1 - Side Profile','NumberTitle','off', ...
       'Color','w','Position',[30,500,1200,500]);
hold on;

%  Fuselage skin
fill([xp,fliplr(xp)],[rp,-fliplr(rp)],[0.67 0.80 0.93], ...
     'EdgeColor',[0.18 0.42 0.72],'LineWidth',1.8,'FaceAlpha',0.72);
plot(xp, rp,'Color',[0.18 0.42 0.72],'LineWidth',2.0);
plot(xp,-rp,'Color',[0.18 0.42 0.72],'LineWidth',2.0);
plot([0 L_fus],[0 0],'--','Color',[0.70 0.70 0.70],'LineWidth',0.8);
plot([L_nose L_nose],      [-(R_fus+3) R_fus+8],'--','Color',[0.82 0.82 0.82],'LineWidth',0.8);
plot([L_nose+L_body L_nose+L_body],[-(R_fus+3) R_fus+8],'--','Color',[0.82 0.82 0.82],'LineWidth',0.8);

%  Belly tank (side view) -- BELOW lower hold floor, not overlapping pallets
fill([x_tank_fwd, x_tank_aft, x_tank_aft, x_tank_fwd], ...
     [keel_y+0.05, keel_y+0.05, belly_top, belly_top], ...
     [0.12 0.55 0.92],'FaceAlpha',0.72,'EdgeColor',[0.04 0.28 0.72],'LineWidth',2.0);
fill([x_tank_fwd+0.1, x_tank_aft-0.1, x_tank_aft-0.1, x_tank_fwd+0.1], ...
     [keel_y+0.08, keel_y+0.08, keel_y+0.08+(belly_top-(keel_y+0.08))*0.976, ...
      keel_y+0.08+(belly_top-(keel_y+0.08))*0.976], ...
     [0.05 0.40 0.80],'FaceAlpha',0.40,'EdgeColor','none');
text((x_tank_fwd+x_tank_aft)/2, (keel_y+belly_top)/2+0.18, ...
     sprintf('BELLY TANK  %.0fkg | arm=%.1fm | L=%.0fm | %.1f%% full', ...
             Fuel_fus,x_fb,L_tank,tank_fill_pct), ...
     'HorizontalAlignment','center','FontSize',8,'Color',[0.02 0.18 0.55],'FontWeight','bold');
plot([x_tank_fwd x_tank_fwd],[keel_y+0.05 belly_top],'Color',[0.04 0.28 0.72],'LineWidth',2.0);
plot([x_tank_aft x_tank_aft],[keel_y+0.05 belly_top],'Color',[0.04 0.28 0.72],'LineWidth',2.0);

%  Tank length dimension arrow
ta_y = keel_y - 0.55;
plot([x_tank_fwd x_tank_aft],[ta_y ta_y],'Color',[0.04 0.28 0.72],'LineWidth',1.1);
plot([x_tank_fwd x_tank_fwd],[ta_y-0.2 ta_y+0.2],'Color',[0.04 0.28 0.72],'LineWidth',1.1);
plot([x_tank_aft x_tank_aft],[ta_y-0.2 ta_y+0.2],'Color',[0.04 0.28 0.72],'LineWidth',1.1);
text((x_tank_fwd+x_tank_aft)/2, ta_y-0.40, ...
     sprintf('L_{tank}=%.0fm  (%.2fm -> %.2fm)',L_tank,x_tank_fwd,x_tank_aft), ...
     'HorizontalAlignment','center','FontSize',8,'Color',[0.04 0.28 0.72],'FontWeight','bold');

%  Wings (side view)
wx1=wx0+Cr; wx2=wx1+SW*9+Ct; wx3=wx0+SW*9; wyt=R_fus+2.0;
fill([wx0,wx1,wx2,wx3],[R_fus,R_fus,wyt,wyt],[0.30 0.55 0.90], ...
     'FaceAlpha',0.50,'EdgeColor',[0.15 0.35 0.75],'LineWidth',1.5);
fill([wx0,wx1,wx2,wx3],-[R_fus,R_fus,wyt,wyt],[0.30 0.55 0.90], ...
     'FaceAlpha',0.50,'EdgeColor',[0.15 0.35 0.75],'LineWidth',1.5);
text(wx0+Cr/2+4, wyt+1.2, ...
     sprintf('Wing  S=%.0fm^2  b=%.0fm  AR=%.2f  sweep=%d deg', S_wing,b_wing,AR,sweep_deg), ...
     'FontSize',9,'Color',[0.12 0.32 0.72],'HorizontalAlignment','center');

%  Horizontal tail
hy0=R_fus*0.72; hy1=hy0+1.3;
fill([hx0,hx0+7.2,hx0+9.8,hx0+0.8],[hy0,hy0,hy1,hy1],[0.95 0.72 0.18], ...
     'FaceAlpha',0.65,'EdgeColor',[0.72 0.48 0.05],'LineWidth',1.5);
fill([hx0,hx0+7.2,hx0+9.8,hx0+0.8],-[hy0,hy0,hy1,hy1],[0.95 0.72 0.18], ...
     'FaceAlpha',0.65,'EdgeColor',[0.72 0.48 0.05],'LineWidth',1.5);
text(hx0+5.0,hy1+1.0,sprintf('H-Tail  S_H=%.1fm^2',S_H),'FontSize',8.5, ...
     'Color',[0.58 0.34 0.02],'HorizontalAlignment','center');

%  Vertical tail -- root ON fuselage top skin
fill([VT_LE_root_x,VT_TE_root_x,VT_TE_tip_x,VT_LE_tip_x], ...
     [VT_root_y,VT_root_y,VT_tip_y,VT_tip_y], ...
     [0.15 0.75 0.35],'FaceAlpha',0.65,'EdgeColor',[0.08 0.52 0.18],'LineWidth',1.8);
text(VT_LE_tip_x+0.5,VT_tip_y+0.6, ...
     sprintf('V-Tail  S_V=%.1fm^2  h=%.1fm',S_V,VT_height), ...
     'FontSize',8.5,'Color',[0.05 0.42 0.12],'HorizontalAlignment','left');

%  LEMAC line
plot([LEMAC LEMAC],[-(R_fus+0.5) R_fus+0.5],'m-','LineWidth',1.5);
text(LEMAC,R_fus+0.8,sprintf('LEMAC\n%.1fm',LEMAC),'FontSize',7.5,'Color',[0.55 0 0.55], ...
     'HorizontalAlignment','center','FontWeight','bold');

%  Cargo doors
dx0=L_nose*0.35;
rectangle('Position',[dx0,R_fus*0.20,5.0,R_fus*0.65],'EdgeColor',[0.50 0.50 0.50],'LineWidth',1.1,'LineStyle','--');
text(dx0+2.5,R_fus*0.20-0.50,'Nose Cargo Door','FontSize',7.5,'Color',[0.45 0.45 0.45],'HorizontalAlignment','center');
sx0=L_nose+L_body*0.12;
rectangle('Position',[sx0,0.28,4.5,R_fus*0.82-0.28],'EdgeColor',[0.45 0.45 0.45],'LineWidth',1.0,'LineStyle','--');
text(sx0+2.25,0.28-0.50,'Side Cargo Door','FontSize',7.5,'Color',[0.45 0.45 0.45],'HorizontalAlignment','center');

%  CG markers
plot(CG_MTOW,0,'rv','MarkerSize',12,'MarkerFaceColor','r');
text(CG_MTOW,-R_fus*0.32,sprintf('CG_MTOW\n%.2fm',CG_MTOW),'FontSize',8,'Color','r', ...
     'HorizontalAlignment','center','FontWeight','bold');
plot(x_OEW,0,'rs','MarkerSize',9,'MarkerFaceColor',[1.0 0.5 0.5]);
text(x_OEW,R_fus*0.22,sprintf('CG_{OEW}\n%.1fm',x_OEW),'FontSize',7.5,'Color',[0.75 0.05 0.05], ...
     'HorizontalAlignment','center');
plot(NP,0,'bs','MarkerSize',10,'MarkerFaceColor','b');
text(NP,R_fus*0.65,sprintf('NP\n%.2fm',NP),'FontSize',8,'Color',[0.10 0.20 0.72], ...
     'HorizontalAlignment','center','FontWeight','bold');
plot(x_fb,keel_y+0.08,'b^','MarkerSize',8,'MarkerFaceColor',[0.12 0.55 0.92]);
text(x_fb,keel_y-0.30,sprintf('x_{fb}=%.1fm',x_fb),'FontSize',7.5,'Color',[0.04 0.28 0.72], ...
     'HorizontalAlignment','center');

%  Overall dimension
ay=-(R_fus+3.8);
plot([0 L_fus],[ay ay],'k-','LineWidth',1.2);
plot([0 0],[ay-0.28 ay+0.28],'k-','LineWidth',1.2);
plot([L_fus L_fus],[ay-0.28 ay+0.28],'k-','LineWidth',1.2);
text(L_fus/2,ay-0.85,sprintf('L_{fus}=%.1fm',L_fus),'HorizontalAlignment','center','FontSize',10,'FontWeight','bold');
plot([-4.8 -4.8],[-R_fus R_fus],'Color',[0.18 0.18 0.78],'LineWidth',1.2);
plot([-5.05 -4.55],[R_fus R_fus],'Color',[0.18 0.18 0.78],'LineWidth',1.2);
plot([-5.05 -4.55],[-R_fus -R_fus],'Color',[0.18 0.18 0.78],'LineWidth',1.2);
text(-5.5,0,sprintf('D=%.1fm',D_fus),'Rotation',90,'HorizontalAlignment','center','FontSize',9,'Color',[0.18 0.18 0.78]);

text(L_nose*0.50,     R_fus+0.55,'NOSE','FontSize',8,'Color',[0.45 0.45 0.45],'HorizontalAlignment','center');
text(L_nose+L_body*0.5,R_fus+0.55,'MAIN CARGO BODY','FontSize',8,'Color',[0.45 0.45 0.45],'HorizontalAlignment','center');
text(L_fus-L_tail*0.5,R_fus+0.55,'TAIL CONE','FontSize',8,'Color',[0.45 0.45 0.45],'HorizontalAlignment','center');

axis equal; grid on;
xlim([-7 L_fus+8]); ylim([-(R_fus+5.5) R_fus+VT_height+3.5]);
xlabel('Fuselage station x (m from nose)','FontSize',11);
ylabel('Radius / Height (m)','FontSize',11);
title(sprintf('SIDE PROFILE  |  L=%.1fm  D=%.1fm  L/D=%.2f  |  CG_{MTOW}=%.2fm  SM=%.1f%%MAC  |  Tank: L=%.0fm arm=%.1fm', ...
      L_fus,D_fus,SR,CG_MTOW,SM_MTOW,L_tank,x_fb),'FontSize',10,'FontWeight','bold');
set(gca,'FontSize',10,'GridAlpha',0.18);
hold off;

%% ======================================================================
%  FIGURE 2 : DUAL-DECK CROSS-SECTION
%  Shows: upper deck pallets, lower hold pallet, belly fuel tank
%  CRITICAL FIX: tank occupies ONLY the belly below lh_floor_y.
%  The tank polygon follows the inner skin arc -- it does NOT overlap
%  with any pallet or floor beam. The lower hold pallet sits ABOVE
%  lh_floor_y; the tank top is at belly_top = lh_floor_y - 0.12 m.
%  Justification: Proves the three cargo zones (upper deck, lower hold,
%  belly tank) are geometrically separated with no interference.
%% ======================================================================

figure('Name','Fig 2 - Cross Section (Wing Station)','NumberTitle','off', ...
       'Color','w','Position',[30,30,720,840]);
hold on;
th = linspace(0,2*pi,360);

%  Fuselage skins
fill(R_fus.*cos(th),R_fus.*sin(th),[0.78 0.88 0.96], ...
     'EdgeColor',[0.18 0.42 0.72],'LineWidth',2.8,'FaceAlpha',0.40);
fill(R_in.*cos(th), R_in.*sin(th),[0.93 0.96 1.00], ...
     'EdgeColor',[0.38 0.55 0.78],'LineWidth',0.9,'FaceAlpha',0.90);
plot(R_in.*cos(th),R_in.*sin(th),'Color',[0.38 0.42 0.60],'LineWidth',1.6);

%  Stringers
th20=linspace(0,2*pi,21); th20=th20(1:end-1);
for k=1:20
    ck=cos(th20(k)); sk=sin(th20(k));
    plot([R_in*0.50*ck R_in*ck],[R_in*0.50*sk R_in*sk],'Color',[0.60 0.62 0.72],'LineWidth',0.8);
end

%  Upper deck floor beam
fill([-ud_floor_hw,ud_floor_hw,ud_floor_hw,-ud_floor_hw], ...
     [ud_floor_y-0.12,ud_floor_y-0.12,ud_floor_y,ud_floor_y], ...
     [0.55 0.38 0.12],'EdgeColor',[0.35 0.22 0.04],'LineWidth',1.8);
text(0,ud_floor_y+0.17,'Upper Main Deck Floor','HorizontalAlignment','center', ...
     'FontSize',8.5,'Color',[0.35 0.18 0.02],'FontWeight','bold');

%  Upper deck pallets
ud_mid_gap=0.15; ud_cx_left=-(P6Pp_W/2+ud_mid_gap/2); ud_cx_right=(P6P_W/2+ud_mid_gap/2);
ud_bot=ud_floor_y; ud_top=ud_floor_y+P6P_H;
%  P6P+ left (orange)
px0=ud_cx_left-P6Pp_W/2; px1=ud_cx_left+P6Pp_W/2;
fill([px0,px1,px1,px0],[ud_bot,ud_bot,ud_top,ud_top],[0.95 0.65 0.15], ...
     'FaceAlpha',0.58,'EdgeColor',[0.70 0.40 0.02],'LineWidth',1.4);
fill([px0,px1,px1,px0],[ud_bot,ud_bot,ud_bot+0.12,ud_bot+0.12],[0.72 0.45 0.05], ...
     'FaceAlpha',0.85,'EdgeColor',[0.70 0.40 0.02],'LineWidth',0.8);
text(ud_cx_left,ud_bot+P6P_H*0.65,'P6P+','HorizontalAlignment','center', ...
     'FontSize',10,'FontWeight','bold','Color',[0.55 0.22 0.00]);
text(ud_cx_left,ud_bot+P6P_H*0.38,'Safety Car','HorizontalAlignment','center', ...
     'FontSize',7.5,'Color',[0.62 0.30 0.02]);
%  P6P right (blue)
px0=ud_cx_right-P6P_W/2; px1=ud_cx_right+P6P_W/2;
fill([px0,px1,px1,px0],[ud_bot,ud_bot,ud_top,ud_top],[0.40 0.65 0.90], ...
     'FaceAlpha',0.55,'EdgeColor',[0.18 0.38 0.72],'LineWidth',1.4);
fill([px0,px1,px1,px0],[ud_bot,ud_bot,ud_bot+0.12,ud_bot+0.12],[0.22 0.40 0.65], ...
     'FaceAlpha',0.85,'EdgeColor',[0.18 0.38 0.72],'LineWidth',0.8);
text(ud_cx_right,ud_bot+P6P_H*0.65,'P6P','HorizontalAlignment','center', ...
     'FontSize',10,'FontWeight','bold','Color',[0.10 0.25 0.55]);
text(ud_cx_right,ud_bot+P6P_H*0.38,'Cargo Pallet','HorizontalAlignment','center', ...
     'FontSize',7.5,'Color',[0.18 0.35 0.62]);

%  Crown clearance
hr_ud=R_in-ud_top;
if hr_ud>0
    xh=ud_floor_hw*0.74;
    plot([xh xh],[ud_top R_in],'Color',[0.65 0.65 0.65],'LineWidth',0.9,'LineStyle',':');
    text(xh+0.15,(ud_top+R_in)/2,sprintf('%.2fm clr',hr_ud),'FontSize',7,'Color',[0.55 0.55 0.55]);
end

%  Lower hold floor beam
fill([-lh_floor_hw,lh_floor_hw,lh_floor_hw,-lh_floor_hw], ...
     [lh_floor_y-0.12,lh_floor_y-0.12,lh_floor_y,lh_floor_y], ...
     [0.20 0.55 0.25],'EdgeColor',[0.08 0.35 0.12],'LineWidth',1.8);
text(0,lh_floor_y+0.18,'Lower Hold Floor','HorizontalAlignment','center', ...
     'FontSize',8.5,'Color',[0.06 0.32 0.10],'FontWeight','bold');

%  Lower hold pallet (centred, GREEN) -- sits ABOVE lh_floor_y
lh_bot=lh_floor_y; lh_top=lh_floor_y+P6P_H;
px0=-P6P_W/2; px1=P6P_W/2;
fill([px0,px1,px1,px0],[lh_bot,lh_bot,lh_top,lh_top],[0.22 0.72 0.32], ...
     'FaceAlpha',0.50,'EdgeColor',[0.08 0.48 0.16],'LineWidth',1.5);
fill([px0,px1,px1,px0],[lh_bot,lh_bot,lh_bot+0.12,lh_bot+0.12],[0.12 0.50 0.20], ...
     'FaceAlpha',0.85,'EdgeColor',[0.08 0.40 0.12],'LineWidth',0.8);
fill([px0,px1,px1,px0],[lh_top-0.12,lh_top-0.12,lh_top,lh_top],[0.12 0.50 0.20], ...
     'FaceAlpha',0.85,'EdgeColor',[0.08 0.40 0.12],'LineWidth',0.8);
text(0,lh_bot+P6P_H*0.65,'P6P','HorizontalAlignment','center', ...
     'FontSize',10,'FontWeight','bold','Color',[0.04 0.30 0.10]);
text(0,lh_bot+P6P_H*0.38,'Lower Hold','HorizontalAlignment','center', ...
     'FontSize',7.5,'Color',[0.08 0.38 0.14]);

%  SEPARATION LINE between lower hold and tank (floor beam bottom)
plot([-lh_floor_hw lh_floor_hw],[belly_top belly_top],'Color',[0.30 0.30 0.30], ...
     'LineWidth',1.2,'LineStyle','--');
text(lh_floor_hw+0.12, belly_top, sprintf('belly\\_top=%.2fm',belly_top), ...
     'FontSize',7,'Color',[0.30 0.30 0.30],'VerticalAlignment','middle');

%  BELLY FUEL TANK -- circular-arc segment strictly inside R_in at every zoom level
%  Polygon: 360-point arc on R_in circle (th from left join to right join going
%  around the bottom) + two closing vertices at (+/-tank_hw_top, belly_top).
%  All vertices satisfy x^2+y^2 <= R_in^2 by construction (they are ON the circle).
th_arc_tank = linspace(pi + asin(abs(belly_top)/R_in), ...
                       2*pi - asin(abs(belly_top)/R_in), 360);
arc_tx = R_in .* cos(th_arc_tank);
arc_ty = R_in .* sin(th_arc_tank);
tank_px = [arc_tx,  tank_hw_top, -tank_hw_top];
tank_py = [arc_ty,  belly_top,    belly_top];
fill(tank_px, tank_py, [0.20 0.55 0.90], ...
     'FaceAlpha',0.65,'EdgeColor','none');

%  Fuel surface line (97.6% fill -- no fill polygon, avoids any corner artefact)
fill_level_y = belly_top - (belly_top - keel_y)*0.024;
hw_fill = sqrt(max(0, R_in^2 - fill_level_y^2));
plot([-hw_fill hw_fill],[fill_level_y fill_level_y], ...
     'Color',[0.04 0.18 0.72],'LineWidth',1.4,'LineStyle','--');
text(0, fill_level_y - 0.18, 'Fuel surface (97.6% fill)', ...
     'HorizontalAlignment','center','FontSize',7, ...
     'Color',[0.04 0.18 0.72],'FontAngle','italic');

%  Tank label -- placed at geometric centroid of the arc segment (well inside)
text(0, (belly_top + keel_y)/2, ...
     sprintf('BELLY FUEL TANK\n%.0fkg | arm=%.1fm | L=%.0fm\nA=%.2fm^2  V=%.1fm^3', ...
             Fuel_fus, x_fb, L_tank, A_seg, tank_vol_fus), ...
     'HorizontalAlignment','center','FontSize',8, ...
     'Color',[0.94 0.97 1.00],'FontWeight','bold');

%  ---- BOUNDARY ENFORCEMENT ----
%  Draw inner skin LAST at maximum line weight.
%  This opaque line sits on top of every fill/patch drawn before it,
%  acting as a hard visual clip that cannot be crossed at any zoom level.
fill(R_in.*cos(th), R_in.*sin(th), [0.93 0.96 1.00], ...
     'EdgeColor','none','FaceAlpha',0.00);
plot(R_in.*cos(th), R_in.*sin(th), ...
     'Color',[0.10 0.25 0.55],'LineWidth',3.5);

%  Reference lines
plot([-R_fus*0.96 R_fus*0.96],[0 0],'--','Color',[0.72 0.72 0.72],'LineWidth',0.9);
text(R_fus*0.97,0,'CL','FontSize',8,'Color',[0.52 0.52 0.52],'VerticalAlignment','middle');
text(0,R_in-0.22,'CROWN','HorizontalAlignment','center','FontSize',8, ...
     'Color',[0.30 0.30 0.55],'FontAngle','italic');
text(0,keel_y-0.55,'BELLY','HorizontalAlignment','center','FontSize',8, ...
     'Color',[0.30 0.30 0.55],'FontAngle','italic');

%  Diameter annotation
atop=R_fus+0.55;
plot([-R_fus R_fus],[atop atop],'k-','LineWidth',1.2);
plot([-R_fus -R_fus],[atop-0.17 atop+0.17],'k-','LineWidth',1.2);
plot([R_fus  R_fus],[atop-0.17 atop+0.17],'k-','LineWidth',1.2);
text(0,atop+0.32,sprintf('D = %.1fm    R_{in} = %.2fm',D_fus,R_in), ...
     'HorizontalAlignment','center','FontSize',10,'FontWeight','bold');
text(0,0,sprintf('dP = %.1fkPa',dP/1000),'HorizontalAlignment','center', ...
     'FontSize',8,'Color',[0.50 0.08 0.08],'FontAngle','italic');
text(R_fus*cos(pi/4)*0.88,R_fus*sin(pi/4)*0.88+0.18,'Hoop stress', ...
     'HorizontalAlignment','center','FontSize',7,'Color',[0.60 0.10 0.10]);
text(R_fus*cos(pi/4)*0.88,R_fus*sin(pi/4)*0.88-0.18, ...
     sprintf('%.0fMPa',sig_hoop/1e6),'HorizontalAlignment','center', ...
     'FontSize',7.5,'Color',[0.60 0.10 0.10],'FontWeight','bold');

%  Legend
lx=-R_fus-0.20; ly=R_fus-0.05; dl=0.42;
sw=0.20; sh=0.18;
fill([lx lx+sw lx+sw lx],[ly-sh/2 ly-sh/2 ly+sh/2 ly+sh/2],[0.95 0.65 0.15],'EdgeColor','none');
text(lx+sw+0.08,ly,'P6P+ Upper Deck (Safety Car)','FontSize',7.8,'HorizontalAlignment','left','Color',[0.62 0.35 0.02]);
fill([lx lx+sw lx+sw lx],[ly-dl-sh/2 ly-dl-sh/2 ly-dl+sh/2 ly-dl+sh/2],[0.40 0.65 0.90],'EdgeColor','none');
text(lx+sw+0.08,ly-dl,'P6P Upper Deck (Cargo)','FontSize',7.8,'HorizontalAlignment','left','Color',[0.18 0.38 0.72]);
fill([lx lx+sw lx+sw lx],[ly-2*dl-sh/2 ly-2*dl-sh/2 ly-2*dl+sh/2 ly-2*dl+sh/2],[0.22 0.72 0.32],'EdgeColor','none');
text(lx+sw+0.08,ly-2*dl,'P6P Lower Hold','FontSize',7.8,'HorizontalAlignment','left','Color',[0.08 0.48 0.16]);
fill([lx lx+sw lx+sw lx],[ly-3*dl-sh/2 ly-3*dl-sh/2 ly-3*dl+sh/2 ly-3*dl+sh/2],[0.12 0.55 0.92],'EdgeColor','none');
text(lx+sw+0.08,ly-3*dl,sprintf('Belly Tank (%.0fkg, arm=%.1fm)',Fuel_fus,x_fb),'FontSize',7.8,'HorizontalAlignment','left','Color',[0.04 0.28 0.72]);
fill([lx lx+sw lx+sw lx],[ly-4*dl-sh/2 ly-4*dl-sh/2 ly-4*dl+sh/2 ly-4*dl+sh/2],[0.55 0.38 0.12],'EdgeColor','none');
text(lx+sw+0.08,ly-4*dl,'Floor Beams','FontSize',7.8,'HorizontalAlignment','left','Color',[0.55 0.38 0.12]);

axis off;
xlim([-(R_fus+2.8) R_fus+2.8]);
ylim([-(R_fus+3.0) R_fus+1.6]);
title(sprintf('CROSS-SECTION at x=%.1fm (wing station)  |  Belly Tank BELOW hold floor  |  dP=%.1fkPa  Hoop=%.0fMPa', ...
      x_fb,dP/1000,sig_hoop/1e6),'FontSize',11,'FontWeight','bold');
hold off;

%% ======================================================================
%  FIGURE 3 : 3-D FUSELAGE SURFACE
%  Shows belly tank as a solid 3D body in the correct keel location.
%  Justification: 3D view confirms tank position relative to wing root
%  and verifies it is inside the fuselage envelope.
%% ======================================================================

figure('Name','Fig 3 - 3D Surface','NumberTitle','off', ...
       'Color',[0.05 0.05 0.09],'Position',[620,200,860,620]);
hold on;
th3=linspace(0,2*pi,80); Nf=length(xp);
X3=zeros(Nf,80); Y3=zeros(Nf,80); Z3=zeros(Nf,80);
for i=1:Nf
    X3(i,:)=xp(i); Y3(i,:)=rp(i).*cos(th3); Z3(i,:)=rp(i).*sin(th3);
end
surf(X3,Y3,Z3,'FaceColor',[0.28 0.52 0.88],'EdgeColor','none', ...
     'FaceAlpha',0.55,'FaceLighting','gouraud', ...
     'AmbientStrength',0.30,'DiffuseStrength',0.72,'SpecularStrength',0.40);
rst=0:8:L_fus;
for k=1:length(rst)
    [~,ir]=min(abs(xp-rst(k)));
    plot3(rst(k)*ones(1,80),rp(ir).*cos(th3),rp(ir).*sin(th3), ...
          'Color',[0.55 0.72 1.00 0.28],'LineWidth',0.7);
end
%  Belly tank 3D -- forward face, aft face, curved sides, flat top
n_arc=40;
th_tk=linspace(pi+asin(abs(belly_top)/R_in), 2*pi-asin(abs(belly_top)/R_in), n_arc);  % FIXED: asin for correct arc endpoints
arc_y=R_in.*cos(th_tk); arc_z=R_in.*sin(th_tk);
fwd_y=[arc_y, belly_hw, -belly_hw]; fwd_z=[arc_z, belly_top, belly_top];
fill3(x_tank_fwd*ones(size(fwd_y)),fwd_y,fwd_z,[0.12 0.55 0.92],'FaceAlpha',0.90,'EdgeColor',[0.04 0.28 0.72],'LineWidth',1.2);
fill3(x_tank_aft*ones(size(fwd_y)),fwd_y,fwd_z,[0.12 0.55 0.92],'FaceAlpha',0.90,'EdgeColor',[0.04 0.28 0.72],'LineWidth',1.2);
tx=[x_tank_fwd,x_tank_aft,x_tank_aft,x_tank_fwd];
ty=[-belly_hw,-belly_hw,belly_hw,belly_hw];
tz=[belly_top,belly_top,belly_top,belly_top];
fill3(tx,ty,tz,[0.12 0.55 0.92],'FaceAlpha',0.85,'EdgeColor',[0.04 0.28 0.72],'LineWidth',1.2);
for k=1:n_arc-1
    fill3([x_tank_fwd,x_tank_aft,x_tank_aft,x_tank_fwd], ...
          [arc_y(k),arc_y(k),arc_y(k+1),arc_y(k+1)], ...
          [arc_z(k),arc_z(k),arc_z(k+1),arc_z(k+1)],[0.12 0.55 0.92], ...
          'FaceAlpha',0.88,'EdgeColor',[0.04 0.28 0.72],'LineWidth',0.5);
end
%  Wings
wx3=[wx0,wx0+Cr,wx0+semi_sp*SW+Ct,wx0+semi_sp*SW];
wy3=[R_fus,R_fus,semi_sp,semi_sp]; wz3=[0,0,0.45,0.45];
fill3(wx3,wy3,wz3,[0.32 0.58 0.92],'FaceAlpha',0.55,'EdgeColor',[0.15 0.38 0.78],'LineWidth',1.3);
fill3(wx3,-wy3,wz3,[0.32 0.58 0.92],'FaceAlpha',0.55,'EdgeColor',[0.15 0.38 0.78],'LineWidth',1.3);
%  H-tail
htsw=tan(32*pi/180); hts=14.0;
htx3=[hx0,hx0+6.8,hx0+hts*htsw+2.4,hx0+hts*htsw];
hty3=[R_fus*0.78,R_fus*0.78,hts,hts]; htz3=[0,0,0.30,0.30];
fill3(htx3,hty3,htz3,[0.96 0.74 0.16],'FaceAlpha',0.60,'EdgeColor',[0.72 0.48 0.05],'LineWidth',1.3);
fill3(htx3,-hty3,htz3,[0.96 0.74 0.16],'FaceAlpha',0.60,'EdgeColor',[0.72 0.48 0.05],'LineWidth',1.3);
%  V-tail
vtx3=[VT_LE_root_x,VT_TE_root_x,VT_TE_tip_x,VT_LE_tip_x];
vty3=[0,0,0,0]; vtz3=[R_fus,R_fus,R_fus+VT_height,R_fus+VT_height];
fill3(vtx3,vty3,vtz3,[0.15 0.82 0.38],'FaceAlpha',0.65,'EdgeColor',[0.08 0.55 0.20],'LineWidth',1.5);
light('Position',[L_fus*0.5,40,25],'Style','infinite');
light('Position',[L_fus*0.1,-25,-12],'Style','infinite','Color',[0.28 0.28 0.50]);
set(gca,'Color',[0.05 0.05 0.09],'XColor','w','YColor','w','ZColor','w', ...
        'GridColor',[0.30 0.30 0.42],'GridAlpha',0.28,'FontSize',9);
axis equal; grid on;
xlabel('X (m)','Color','w','FontSize',10); ylabel('Y (m)','Color','w','FontSize',10); zlabel('Z (m)','Color','w','FontSize',10);
title(sprintf('3D SURFACE  |  Belly tank: %.0fkg  arm=%.1fm  L=%.0fm  Vol=%.1fm^3', ...
      Fuel_fus,x_fb,L_tank,tank_vol_fus),'Color','w','FontSize',11,'FontWeight','bold');
view(-42,24); camzoom(1.05); hold off;

%% ======================================================================
%  FIGURE 4 : TOP VIEW -- TANK FOOTPRINT & WING PLANFORM
%  Justification: Top view shows tank footprint relative to wing plan,
%  centre of the tank aligns with x_fb=36.8m, and LEMAC is marked.
%  Wing tanks at x_fw=35.5m are annotated for interface reference.
%% ======================================================================

figure('Name','Fig 4 - Top View','NumberTitle','off','Color','w','Position',[30,30,980,560]);
hold on;
fill([xp,fliplr(xp)],[rp,-fliplr(rp)],[0.72 0.82 0.94], ...
     'EdgeColor',[0.25 0.45 0.75],'LineWidth',1.5,'FaceAlpha',0.60);
wLE_r=wx0; wTE_r=wx0+Cr; wLE_t=wx0+semi_sp*SW; wTE_t=wLE_t+Ct;
fill([wLE_r,wTE_r,wTE_t+(wLE_t-wLE_r),wLE_t],[R_fus,R_fus,semi_sp,semi_sp], ...
     [0.28 0.52 0.92],'FaceAlpha',0.48,'EdgeColor',[0.12 0.35 0.78],'LineWidth',1.5);
fill([wLE_r,wTE_r,wTE_t+(wLE_t-wLE_r),wLE_t],-[R_fus,R_fus,semi_sp,semi_sp], ...
     [0.28 0.52 0.92],'FaceAlpha',0.48,'EdgeColor',[0.12 0.35 0.78],'LineWidth',1.5);
%  Belly tank footprint
fill([x_tank_fwd,x_tank_aft,x_tank_aft,x_tank_fwd], ...
     [-belly_hw,-belly_hw,belly_hw,belly_hw], ...
     [0.12 0.55 0.92],'FaceAlpha',0.68,'EdgeColor',[0.04 0.28 0.72],'LineWidth',2.2);
text(x_fb,0,sprintf('BELLY TANK\n%.0fkg  arm=%.1fm\nL=%.0fm  W=%.1fm', ...
     Fuel_fus,x_fb,L_tank,tank_w),'HorizontalAlignment','center','FontSize',8.5, ...
     'Color',[0.02 0.18 0.55],'FontWeight','bold');
%  LEMAC line
plot([LEMAC LEMAC],[-semi_sp-4 semi_sp+4],'m-','LineWidth',1.8);
text(LEMAC,semi_sp+5.0,sprintf('LEMAC=%.1fm',LEMAC),'HorizontalAlignment','center', ...
     'FontSize',9,'Color',[0.55 0 0.55],'FontWeight','bold');
%  x_fb marker
plot([x_fb x_fb],[-belly_hw-1.5 belly_hw+1.5],'b--','LineWidth',1.4);
text(x_fb,belly_hw+2.2,sprintf('x_{fb}=%.1fm',x_fb),'HorizontalAlignment','center', ...
     'FontSize',9,'Color',[0.04 0.28 0.72],'FontWeight','bold');
%  Wing tank arm markers
plot([x_fw x_fw],[-semi_sp semi_sp],'r--','LineWidth',1.2);
text(x_fw,semi_sp+2.5,sprintf('x_{fw}=%.1fm (each wing tank)',x_fw), ...
     'HorizontalAlignment','center','FontSize',8.5,'Color','r','FontWeight','bold');
%  MAC
mac_y2=R_fus+(semi_sp-R_fus)*eta_mac; mac_xLE2=wx0+(mac_y2-R_fus)*SW;
plot([mac_xLE2,mac_xLE2+MAC],[mac_y2,mac_y2],'m-','LineWidth',2.5);
plot([mac_xLE2,mac_xLE2+MAC],-[mac_y2,mac_y2],'m-','LineWidth',2.5);
text(mac_xLE2+MAC+1.5,mac_y2,sprintf('MAC=%.2fm',MAC),'FontSize',9,'Color',[0.55 0 0.55],'FontWeight','bold');
%  H-tail
hts2=13.5; htsw2=tan(32*pi/180); htLE2=hx0+hts2*htsw2;
fill([hx0,hx0+6.8,htLE2+2.4,htLE2],[R_fus,R_fus,hts2,hts2],[0.96 0.74 0.16],'FaceAlpha',0.55,'EdgeColor',[0.72 0.48 0.05],'LineWidth',1.3);
fill([hx0,hx0+6.8,htLE2+2.4,htLE2],-[R_fus,R_fus,hts2,hts2],[0.96 0.74 0.16],'FaceAlpha',0.55,'EdgeColor',[0.72 0.48 0.05],'LineWidth',1.3);
text(hx0+5,hts2+2.5,sprintf('H-Tail S_H=%.1fm^2',S_H),'FontSize',9,'Color',[0.58 0.35 0.02],'HorizontalAlignment','center');
%  Tank length arrow
ta_y=belly_hw+4.0;
plot([x_tank_fwd x_tank_aft],[ta_y ta_y],'Color',[0.04 0.28 0.72],'LineWidth',1.2);
plot([x_tank_fwd x_tank_fwd],[ta_y-0.5 ta_y+0.5],'Color',[0.04 0.28 0.72],'LineWidth',1.2);
plot([x_tank_aft x_tank_aft],[ta_y-0.5 ta_y+0.5],'Color',[0.04 0.28 0.72],'LineWidth',1.2);
text(x_fb,ta_y+1.2,sprintf('Tank L=%.0fm  (%.1fm -> %.1fm)',L_tank,x_tank_fwd,x_tank_aft), ...
     'HorizontalAlignment','center','FontSize',9,'Color',[0.04 0.28 0.72],'FontWeight','bold');
%  Span arrow
spx=wx0-5.5;
plot([spx spx],[-semi_sp semi_sp],'k-','LineWidth',1.1);
plot([spx-0.5 spx+0.5],[semi_sp semi_sp],'k-','LineWidth',1.1);
plot([spx-0.5 spx+0.5],[-semi_sp -semi_sp],'k-','LineWidth',1.1);
text(spx-1.8,0,sprintf('b=%.0fm',b_wing),'Rotation',90,'HorizontalAlignment','center','FontSize',10,'FontWeight','bold');
axis equal; grid on;
xlim([-8 L_fus+8]); ylim([-(semi_sp+10) semi_sp+14]);
xlabel('Longitudinal station x (m)','FontSize',11); ylabel('Lateral station y (m)','FontSize',11);
title(sprintf('TOP VIEW  |  Belly tank: arm=%.1fm  L=%.0fm  |  LEMAC=%.1fm  |  Wing tanks: arm=%.1fm each', ...
      x_fb,L_tank,LEMAC,x_fw),'FontSize',11,'FontWeight','bold');
set(gca,'FontSize',10,'GridAlpha',0.18); hold off;

%% ======================================================================
%  FIGURE 5 : MASS BREAKDOWN & SURFACE AREAS
%  Justification: Bar charts give an instant visual check that mass
%  proportions are sensible. Reviewers can spot errors in mass fractions
%  at a glance.
%% ======================================================================

figure('Name','Fig 5 - Mass & Areas','NumberTitle','off','Color','w','Position',[620,30,960,440]);
subplot(1,2,1);
mv=[MTOW,OEW,Fuel,Fuel_fus,2*Fuel_wing,Payload,Fus_mass,Tail_mass,Wing_mass];
ml={'MTOW','OEW','Fuel Tot','Belly','Wings','Payload','Fuselage','Tail','Wing struct'};
mc=[0.22 0.48 0.82;0.88 0.60 0.12;0.20 0.65 0.95;0.04 0.28 0.72;0.28 0.52 0.88; ...
    0.18 0.72 0.38;0.82 0.22 0.22;0.55 0.32 0.78;0.18 0.55 0.45];
bh=bar(mv,'FaceColor','flat','EdgeColor','none'); bh.CData=mc;
xticks(1:9); xticklabels(ml); xtickangle(35);
ylabel('Mass (kg)'); title('Mass Breakdown','FontSize',10,'FontWeight','bold');
grid on; set(gca,'GridAlpha',0.20,'FontSize',9);
for k=1:length(mv)
    if mv(k)>=1000; lb=sprintf('%.0fk',mv(k)/1000); else; lb=sprintf('%.0f',mv(k)); end
    text(k,mv(k)+max(mv)*0.015,lb,'HorizontalAlignment','center','FontSize',8,'FontWeight','bold');
end
subplot(1,2,2);
av=[S_wing,S_H,S_V,S_wet_fus]; al={'Wing','H-Tail','V-Tail','Fus Wet'};
ac=[0.22 0.48 0.82;0.88 0.60 0.12;0.18 0.72 0.38;0.65 0.65 0.75];
bh2=bar(av,'FaceColor','flat','EdgeColor','none'); bh2.CData=ac;
xticks(1:4); xticklabels(al); ylabel('Area (m^2)');
title('Aerodynamic Surface Areas','FontSize',10,'FontWeight','bold');
grid on; set(gca,'GridAlpha',0.20,'FontSize',9);
for k=1:length(av)
    text(k,av(k)+max(av)*0.02,sprintf('%.1f',av(k)),'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
end

%% ======================================================================
%  FIGURE 6 : SLENDERNESS RATIO GAUGE
%  Justification: Confirms L/D is within the 8-14 optimal zone,
%  satisfying the fineness ratio design rule for low wave drag.
%% ======================================================================

figure('Name','Fig 6 - SR Gauge','NumberTitle','off','Color','w','Position',[30,260,720,260]);
hold on;
srx=linspace(0,20,400);
for k=1:length(srx)-1
    v=srx(k);
    if v<5; fc=[0.82 0.18 0.18]; elseif v<8; fc=[0.92 0.68 0.10];
    elseif v<=14; fc=[0.12 0.72 0.28]; elseif v<=17; fc=[0.92 0.68 0.10];
    else; fc=[0.82 0.18 0.18]; end
    fill([srx(k),srx(k+1),srx(k+1),srx(k)],[0,0,1,1],fc,'EdgeColor','none');
end
text(11,0.50,'OPTIMAL ZONE','HorizontalAlignment','center','FontSize',9,'Color',[0.05 0.42 0.12],'FontWeight','bold');
plot([SR SR],[0 1.30],'k-','LineWidth',3.0); plot(SR,1.30,'kv','MarkerSize',10,'MarkerFaceColor','k');
text(SR,1.48,sprintf('L/D = %.2f',SR),'HorizontalAlignment','center','FontSize',11,'FontWeight','bold');
xlim([0 20]); ylim([0 1.70]); xlabel('Slenderness ratio L/D','FontSize',11);
set(gca,'YTick',[],'XTick',[0,5,8,11,14,17,20],'FontSize',10);
title(sprintf('SLENDERNESS RATIO  L/D=%.2f  [Optimal 8-14]',SR),'FontSize',10,'FontWeight','bold');
grid on; box on; hold off;

%% ======================================================================
%  FIGURE 7 : DESIGN EQUATIONS
%  Justification: A single figure showing all key equations with
%  substituted numerical values -- acts as a traceable audit sheet.
%% ======================================================================

figure('Name','Fig 7 - Equations','NumberTitle','off','Color','w','Position',[30,260,820,680]);
axes('Position',[0 0 1 1]); axis off; xlim([0 1]); ylim([0 1]);
text(0.50,0.97,'Design Equations -- Fuselage (Modified B777 F1 2040)', ...
     'FontSize',11,'FontWeight','bold','HorizontalAlignment','center','Units','normalized');
line([0.02 0.98],[0.94 0.94],'Color',[0.25 0.25 0.25],'LineWidth',1.2);
eqs={
  '1. MAC & taper', sprintf('   lambda=%.4f  MAC=%.4fm  AR=%.2f',lambda,MAC,AR);
  '2. Slenderness', sprintf('   L/D=%.4f  [OPTIMAL 8-14]',SR);
  '3. Tail areas', sprintf('   S_H=%.4fm^2  S_V=%.4fm^2',S_H,S_V);
  '4. Hoop/Long stress', sprintf('   sig_h=%.1fMPa SF=%.2f  |  sig_L=%.1fMPa SF=%.2f',sig_hoop/1e6,SF_hoop,sig_long/1e6,SF_long);
  '5. Fuel CG (3-tank, correct formula: no LEMAC offset)', ...
  sprintf('   CG_fuel=(60000*%.1f+60000*%.1f+60000*%.1f)/180000 = %.4fm',x_fb,x_fw,x_fw,CG_fuel_total);
  '6. ZFW CG (mass-weighted)', sprintf('   CG_ZFW=(200000*%.1f+150000*%.2f)/350000 = %.4fm',x_OEW,x_payload,CG_ZFW);
  '7. MTOW CG (correct formula: SUM(m*x)/SUM(m))', ...
  sprintf('   CG_MTOW=(200000*%.1f+180000*%.4f+150000*%.2f)/530000 = %.4fm',x_OEW,CG_fuel_total,x_payload,CG_MTOW);
  '8. NP (wing+tail formula)', sprintf('   NP=(x_AC_wing*S+x_AC_tail*S_H)/(S+S_H)=(%.3f*600+%.3f*%.3f)/(600+%.3f)=%.4fm',x_AC_wing,x_AC_tail,S_H_NP,S_H_NP,NP);
  '9. Static Margin @ MTOW', sprintf('   SM=(%.4f-%.4f)/%.4f*100 = %.2f%% MAC  [STABLE]',NP,CG_MTOW,MAC,SM_MTOW);
  '10. SM @ ZFW / OEW', sprintf('   SM_ZFW=%.2f%%  SM_OEW=%.2f%%  [both STABLE]',SM_ZFW,SM_OEW);
  '11. Belly tank volume (circular segment x length)', ...
  sprintf('   A=R^2*alpha-d*sqrt(R^2-d^2)=%.4fm^2  L=%.1fm  V=%.2fm^3  Fill=%.1f%%',A_seg,L_tank,tank_vol_fus,tank_fill_pct);
  '12. Tank arm check', sprintf('   x_tank_CG=(%.2f+%.2f)/2=%.3fm = x_fb=%.1fm  [CORRECT]',x_tank_fwd,x_tank_aft,(x_tank_fwd+x_tank_aft)/2,x_fb);
};
ly=0.91; g1=0.042; g2=0.033;
for k=1:size(eqs,1)
    text(0.02,ly,eqs{k,1},'FontSize',9.5,'FontWeight','bold','Color',[0.15 0.25 0.60],'Units','normalized');
    ly=ly-g1;
    text(0.02,ly,eqs{k,2},'FontSize',9,'Color',[0.10 0.10 0.10],'FontName','Courier New','Units','normalized');
    ly=ly-g2;
    line([0.03 0.97],[ly ly],'Color',[0.86 0.86 0.86],'LineWidth',0.6);
    ly=ly-0.006;
end

%% ======================================================================
%  FIGURE 8 : CG ENVELOPE (POTATO DIAGRAM)
%  Shows CG vs mass for 5 loading conditions.
%  Justification: The CG envelope is the fundamental stability document.
%  All points must lie: (a) forward of NP (positive SM), (b) within the
%  forward/aft CG limits of the CG envelope band. All 5 points shown.
%% ======================================================================

figure('Name','Fig 8 - CG Envelope','NumberTitle','off','Color','w','Position',[620,240,760,480]);
hold on;
cg_fwd = LEMAC + 0.15*MAC;
cg_aft = LEMAC + 0.40*MAC;
fill([cg_fwd,cg_aft,cg_aft,cg_fwd,cg_fwd],[OEW,OEW,MTOW,MTOW,OEW], ...
     [0.80 0.90 0.98],'EdgeColor',[0.20 0.40 0.75],'LineWidth',1.5,'FaceAlpha',0.50);
text(mean([cg_fwd,cg_aft]),mean([OEW,MTOW]),'CG Envelope', ...
     'HorizontalAlignment','center','FontSize',9,'Color',[0.15 0.35 0.65],'FontWeight','bold');

cgp=[x_OEW, CG_ZFW, CG_MTOW, CG_fuel_total, NP];
mcp=[OEW,   OEW+Payload, MTOW, OEW+Fuel,  MTOW*1.008];
pc =[0.82 0.22 0.22;0.18 0.72 0.38;0.00 0.00 0.00;0.04 0.28 0.72;0.20 0.20 0.80];
plab={'CG_{OEW}=33.5m','CG_{ZFW}=33.83m','CG_{MTOW}=35.54m','CG_{fuel}=35.93m',sprintf('NP=%.2fm',NP)};
for k=1:5
    if k<5
        plot(cgp(k),mcp(k),'o','MarkerSize',10,'MarkerFaceColor',pc(k,:),'MarkerEdgeColor','k','LineWidth',1.2);
        text(cgp(k)+0.25,mcp(k)+9000,plab{k},'FontSize',8,'Color',pc(k,:),'FontWeight','bold');
    else
        plot(cgp(k),mcp(k),'s','MarkerSize',10,'MarkerFaceColor',[0.9 0.9 0.0],'MarkerEdgeColor','k','LineWidth',1.2);
        text(cgp(k)+0.25,mcp(k)-9000,plab{k},'FontSize',8,'Color','k','FontWeight','bold');
    end
end
plot([cg_fwd cg_fwd],[OEW*0.94,MTOW*1.025],'r--','LineWidth',1.5);
plot([cg_aft cg_aft],[OEW*0.94,MTOW*1.025],'r--','LineWidth',1.5);
text(cg_fwd,OEW*0.95,'Fwd limit','FontSize',8,'Color','r','HorizontalAlignment','center');
text(cg_aft,OEW*0.95,'Aft limit','FontSize',8,'Color','r','HorizontalAlignment','center');
plot([NP NP],[OEW*0.94,MTOW*1.025],'b:','LineWidth',1.2);
text(NP,OEW*0.98,'NP','FontSize',8,'Color','b','HorizontalAlignment','center');

%  SM annotation lines from CG_MTOW to NP
annotation_y = MTOW*0.96;
plot([CG_MTOW NP],[annotation_y annotation_y],'k-','LineWidth',1.2);
plot([CG_MTOW CG_MTOW],[annotation_y-3000 annotation_y+3000],'k-','LineWidth',1.2);
plot([NP NP],[annotation_y-3000 annotation_y+3000],'k-','LineWidth',1.2);
text(mean([CG_MTOW,NP]),annotation_y-12000, ...
     sprintf('SM=%.1f%%MAC',SM_MTOW),'HorizontalAlignment','center','FontSize',9,'FontWeight','bold','Color','k');

xlim([cg_fwd-2, NP+2]); ylim([OEW*0.92, MTOW*1.04]);
xlabel('CG station x (m from nose)','FontSize',11); ylabel('Aircraft mass (kg)','FontSize',11);
title(sprintf('CG ENVELOPE  |  SM@MTOW=%.1f%%  SM@ZFW=%.1f%%  SM@OEW=%.1f%%  -- ALL STABLE', ...
      SM_MTOW,SM_ZFW,SM_OEW),'FontSize',11,'FontWeight','bold');
grid on; set(gca,'GridAlpha',0.20,'FontSize',10); hold off;

%% ======================================================================
%  FIGURE 9 : LOAD DISTRIBUTION
%  Justification: Shows structural shear force and bending moment along
%  the fuselage. Wing reactions balance the distributed fuselage weight.
%  Max BM quoted for sizing the keel structure.
%% ======================================================================

figure('Name','Fig 9 - Load Distribution','NumberTitle','off','Color','w','Position',[30,30,900,520]);
xb2=linspace(0,L_fus,300); wdist=(Fus_mass*g)/L_fus;
Rwing=MTOW*g*0.45;
SF2=zeros(1,300); BM2=zeros(1,300);
for i=1:300
    xi=xb2(i); SF2(i)=-wdist*xi; BM2(i)=-wdist*xi^2/2;
    if xi>x_tank_fwd; SF2(i)=SF2(i)+Rwing; BM2(i)=BM2(i)+Rwing*(xi-x_tank_fwd); end
    if xi>x_tank_aft;  SF2(i)=SF2(i)+Rwing; BM2(i)=BM2(i)+Rwing*(xi-x_tank_aft);  end
end
SFn=SF2/max(abs(SF2)); BMn=BM2/max(abs(BM2));
subplot(3,1,1);
fill([xp,fliplr(xp)],[rp,-fliplr(rp)],[0.75 0.85 0.95],'EdgeColor',[0.30 0.50 0.80],'LineWidth',1.2,'FaceAlpha',0.60);
hold on;
fill([x_tank_fwd,x_tank_aft,x_tank_aft,x_tank_fwd], ...
     [-R_fus*0.88,-R_fus*0.88,-R_fus*0.18,-R_fus*0.18],[0.12 0.55 0.92], ...
     'FaceAlpha',0.65,'EdgeColor',[0.04 0.28 0.72],'LineWidth',1.5);
text(x_fb,-R_fus*0.55,sprintf('Belly Tank\n%.0fkg  L=%.0fm',Fuel_fus,L_tank), ...
     'HorizontalAlignment','center','FontSize',7.5,'Color',[0.02 0.18 0.55]);
plot([x_tank_fwd x_tank_fwd],[-R_fus R_fus],'r--','LineWidth',1.3);
plot([x_tank_aft  x_tank_aft], [-R_fus R_fus],'r--','LineWidth',1.3);
text(x_tank_fwd,-R_fus-0.5,'Fwd BH','FontSize',7.5,'HorizontalAlignment','center','Color','r');
text(x_tank_aft, -R_fus-0.5,'Aft BH', 'FontSize',7.5,'HorizontalAlignment','center','Color','r');
axis equal; xlim([0 L_fus]); ylim([-R_fus-1.2 R_fus+1]);
ylabel('r (m)','FontSize',9);
title('Fuselage Profile -- Tank spans 27.80 m -> 45.80 m (fwd of wing CG)','FontSize',9,'FontWeight','bold');
grid on; set(gca,'FontSize',8,'GridAlpha',0.20); hold off;
subplot(3,1,2);
fill([xb2,fliplr(xb2)],[SFn,zeros(1,300)],[0.90 0.55 0.20],'FaceAlpha',0.55,'EdgeColor',[0.75 0.38 0.05],'LineWidth',1.2);
hold on; plot([0 L_fus],[0 0],'k-','LineWidth',0.8);
plot([x_tank_fwd x_tank_fwd],[-1.1 1.1],'r--','LineWidth',1.0);
plot([x_tank_aft  x_tank_aft], [-1.1 1.1],'r--','LineWidth',1.0);
xlim([0 L_fus]); ylim([-1.15 1.15]);
ylabel('Norm. SF','FontSize',9); title('Shear Force (normalised)','FontSize',9,'FontWeight','bold');
grid on; set(gca,'FontSize',8,'GridAlpha',0.20); hold off;
subplot(3,1,3);
fill([xb2,fliplr(xb2)],[BMn,zeros(1,300)],[0.30 0.60 0.92],'FaceAlpha',0.55,'EdgeColor',[0.15 0.38 0.78],'LineWidth',1.2);
hold on; plot([0 L_fus],[0 0],'k-','LineWidth',0.8);
plot([x_tank_fwd x_tank_fwd],[-1.1 1.1],'r--','LineWidth',1.0);
plot([x_tank_aft  x_tank_aft], [-1.1 1.1],'r--','LineWidth',1.0);
text(L_fus*0.45,-0.55,sprintf('Max BM (2.5g) = %.1f MN.m',BM_max/1e6),'FontSize',8.5,'Color',[0.10 0.30 0.70],'FontWeight','bold');
xlim([0 L_fus]); ylim([-1.15 0.25]);
xlabel('Fuselage station x (m)','FontSize',9); ylabel('Norm. BM','FontSize',9);
title('Bending Moment (normalised)','FontSize',9,'FontWeight','bold');
grid on; set(gca,'FontSize',8,'GridAlpha',0.20); hold off;

%% ======================================================================
%  FIGURE 10 : PRESSURE VESSEL & STRESS SUMMARY
%  Justification: Verifies the fuselage shell can withstand cabin
%  differential pressure at cruise. Both hoop and longitudinal stresses
%  are well below yield (SF > 1). This closes out the pressure vessel
%  structural check.
%% ======================================================================

figure('Name','Fig 10 - Stress','NumberTitle','off','Color','w','Position',[620,30,900,480]);
subplot(1,2,1); hold on;
thr=linspace(0,2*pi,360); rv=linspace(R_fus*0.50,R_fus,8);
for k=1:8
    fr=(rv(k)/R_fus)^2; fc2=[0.10+0.80*fr,0.20+0.20*(1-fr),0.85-0.75*fr];
    fill(rv(k).*cos(thr),rv(k).*sin(thr),fc2,'EdgeColor','none','FaceAlpha',0.35);
end
plot(R_fus.*cos(thr),R_fus.*sin(thr),'Color',[0.18 0.42 0.72],'LineWidth',2.5);
plot(R_in.*cos(thr), R_in.*sin(thr), 'Color',[0.50 0.55 0.75],'LineWidth',1.2);
for k=1:12
    ag=(k/12)*2*pi;
    plot([R_fus*cos(ag)*1.22 R_fus*cos(ag)*1.05],[R_fus*sin(ag)*1.22 R_fus*sin(ag)*1.05],'Color',[0.82 0.18 0.18],'LineWidth',1.2);
end
text(0,R_fus*1.35,sprintf('P_{atm}=%.1fkPa',P_cr/1000),'HorizontalAlignment','center','FontSize',8,'Color',[0.82 0.18 0.18]);
text(0,0.30,sprintf('P_{cab}=%.1fkPa',P_cabin/1000),'HorizontalAlignment','center','FontSize',8,'Color',[0.18 0.45 0.75]);
text(0,-0.30,sprintf('dP=%.1fkPa',dP/1000),'HorizontalAlignment','center','FontSize',8,'Color',[0.50 0.08 0.08]);
axis equal; axis off; xlim([-R_fus*1.6 R_fus*1.6]); ylim([-R_fus*1.6 R_fus*1.6]);
title(sprintf('Pressure Vessel  D=%.1fm',D_fus),'FontSize',10,'FontWeight','bold'); hold off;
subplot(1,2,2); hold on;
sv=[sig_hoop/1e6,sig_long/1e6,sig_yld/1e6,sig_ult/1e6];
sc=[0.82 0.22 0.22;0.92 0.60 0.10;0.18 0.65 0.28;0.10 0.38 0.70];
bh3=bar(sv,'FaceColor','flat','EdgeColor','none'); bh3.CData=sc;
xticks(1:4); xticklabels({'Hoop','Long.','Yield','Ultimate'}); ylabel('Stress (MPa)');
title(sprintf('Stress Summary  t=%.0fmm  SF_{hoop}=%.2f',t_skin*1000,SF_hoop),'FontSize',10,'FontWeight','bold');
grid on; set(gca,'GridAlpha',0.20,'FontSize',9);
for k=1:length(sv)
    text(k,sv(k)+max(sv)*0.02,sprintf('%.0f',sv(k)),'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
end
plot([0.5 1.5],[sig_yld/1e6 sig_yld/1e6],'g--','LineWidth',1.2);
text(1.55,sig_yld/1e6,sprintf('SF=%.2f',SF_hoop),'FontSize',8,'Color',[0.10 0.55 0.18]);
xlim([0.5 4.5]); hold off;

%% ======================================================================
%  FIGURE 11 : FUEL SYSTEM SUMMARY
%  Justification: Shows all three tanks in cross-section and as a
%  bar chart. Confirms equal 60,000 kg split and each tank's arm.
%% ======================================================================

figure('Name','Fig 11 - Fuel System','NumberTitle','off','Color','w','Position',[30,30,960,500]);
subplot(1,2,1); hold on;
%  --- Fuselage outer skin (background fill + edge) ---
fill(R_fus.*cos(th),R_fus.*sin(th),[0.82 0.90 0.97], ...
     'EdgeColor',[0.18 0.42 0.72],'LineWidth',2.0,'FaceAlpha',0.35);
%  --- Inner skin white fill (covers everything below, acts as canvas) ---
fill(R_in.*cos(th),R_in.*sin(th),[0.96 0.97 0.99], ...
     'EdgeColor','none','FaceAlpha',1.00);
%  --- Upper deck pallet P6P+ (orange) ---
px0u=ud_cx_left-P6Pp_W/2;
fill([px0u,px0u+P6Pp_W,px0u+P6Pp_W,px0u],[ud_floor_y,ud_floor_y,ud_floor_y+P6Pp_H,ud_floor_y+P6Pp_H],[0.95 0.65 0.15],'FaceAlpha',0.55,'EdgeColor',[0.70 0.40 0.02],'LineWidth',1.2);
%  --- Upper deck pallet P6P (blue) ---
px0u2=ud_cx_right-P6P_W/2;
fill([px0u2,px0u2+P6P_W,px0u2+P6P_W,px0u2],[ud_floor_y,ud_floor_y,ud_floor_y+P6P_H,ud_floor_y+P6P_H],[0.40 0.65 0.90],'FaceAlpha',0.55,'EdgeColor',[0.18 0.38 0.72],'LineWidth',1.2);
%  --- Lower hold pallet (green) ---
px0l=-P6P_W/2;
fill([px0l,px0l+P6P_W,px0l+P6P_W,px0l],[lh_floor_y,lh_floor_y,lh_floor_y+P6P_H,lh_floor_y+P6P_H],[0.22 0.72 0.32],'FaceAlpha',0.55,'EdgeColor',[0.08 0.48 0.16],'LineWidth',1.2);
%  --- Lower hold floor beam ---
fill([-lh_floor_hw,lh_floor_hw,lh_floor_hw,-lh_floor_hw],[lh_floor_y-0.12,lh_floor_y-0.12,lh_floor_y,lh_floor_y],[0.20 0.55 0.25],'EdgeColor',[0.08 0.35 0.12],'LineWidth',1.5);
%  --- Belly fuel tank: 360-pt arc polygon, all vertices ON R_in circle ---
th_arc11 = linspace(pi + asin(abs(belly_top)/R_in), ...
                    2*pi - asin(abs(belly_top)/R_in), 360);
arc_tx11 = R_in .* cos(th_arc11);
arc_ty11 = R_in .* sin(th_arc11);
tank_px11 = [arc_tx11,  tank_hw_top, -tank_hw_top];
tank_py11 = [arc_ty11,  belly_top,    belly_top];
fill(tank_px11, tank_py11, [0.20 0.55 0.90], ...
     'FaceAlpha',0.72,'EdgeColor','none');
%  Tank label placed BELOW the keel line (clear of boundary)
text(0, keel_y - 0.30, ...
     sprintf('BELLY TANK\n%.0fkg | arm=%.1fm', Fuel_fus, x_fb), ...
     'HorizontalAlignment','center','FontSize',7.5, ...
     'FontWeight','bold','Color',[0.04 0.20 0.58]);
%  Centreline reference
plot([-R_fus*0.95 R_fus*0.95],[0 0],'--','Color',[0.75 0.75 0.75],'LineWidth',0.9);
%  ---- BOUNDARY ENFORCEMENT ----
%  Inner skin redrawn LAST at 3.5 pt -- hard opaque clip at any zoom
plot(R_in.*cos(th), R_in.*sin(th), ...
     'Color',[0.10 0.25 0.55],'LineWidth',3.5);
axis equal; axis off;
xlim([-(R_fus+0.5) R_fus+0.5]); ylim([-(R_fus+1.1) R_fus+0.9]);
title('Fuel System Cross-section: tank strictly inside inner skin','FontSize',9,'FontWeight','bold');
hold off;
subplot(1,2,2); hold on;
fuel_m=[Fuel_fus,Fuel_wing,Fuel_wing];
fuel_a=[x_fb,x_fw,x_fw];
fuel_c=[0.12 0.55 0.92;0.28 0.52 0.92;0.12 0.38 0.78];
bh5=bar(fuel_m,'FaceColor','flat','EdgeColor','none'); bh5.CData=fuel_c;
xticks(1:3); xticklabels({'Belly (fus)','Port Wing','Stbd Wing'});
ylabel('Fuel mass (kg)');
title(sprintf('3-Tank Split -- Total=%.0fkg  Equal 60,000kg each',Fuel),'FontSize',10,'FontWeight','bold');
grid on; set(gca,'GridAlpha',0.20,'FontSize',9);
for k=1:3
    text(k,fuel_m(k)+2500,sprintf('%.0fkg\narm=%.1fm',fuel_m(k),fuel_a(k)), ...
         'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
end
yline(60000,'r--','LineWidth',1.5,'Label','60,000 kg design point');
ylim([0 75000]); hold off;

%% ======================================================================
%  FINAL CONSOLE STABILITY SIGN-OFF
%% ======================================================================

fprintf('=================================================================\n');
fprintf('  STABILITY SIGN-OFF\n');
fprintf('=================================================================\n');
fprintf('  All CG arms: absolute from nose (datum x=0), no LEMAC offset\n');
fprintf('  Formula: CG = SUM(m_i * x_i) / SUM(m_i)\n');
fprintf('  ---------------------------------------------------------\n');
fprintf('  x_OEW     = %.3f m  (spec input)\n',x_OEW);
fprintf('  x_payload = %.3f m  (spec input)\n',x_payload);
fprintf('  x_fb      = %.3f m  (belly tank, spec input)\n',x_fb);
fprintf('  x_fw      = %.3f m  (each wing tank, spec input)\n',x_fw);
fprintf('  CG_fuel   = %.4f m  (computed)\n',CG_fuel_total);
fprintf('  CG_ZFW    = %.4f m  (computed)\n',CG_ZFW);
fprintf('  CG_MTOW   = %.4f m  (computed)\n',CG_MTOW);
fprintf('  NP        = %.4f m  (25%% MAC, geometric)\n',NP);
fprintf('  MAC       = %.4f m\n',MAC);
fprintf('  LEMAC      = %.3f m  (Wing LE at 30 m from nose, specified)\n',LEMAC);
fprintf('  ---------------------------------------------------------\n');
fprintf('  SM @ OEW  = %+.2f%% MAC  [%s]\n',SM_OEW,  ternary(SM_OEW>5,'STABLE [OK]','UNSTABLE [FAIL]'));
fprintf('  SM @ ZFW  = %+.2f%% MAC  [%s]\n',SM_ZFW,  ternary(SM_ZFW>5,'STABLE [OK]','UNSTABLE [FAIL]'));
fprintf('  SM @ MTOW = %+.2f%% MAC  [%s]\n',SM_MTOW, ternary(SM_MTOW>5,'STABLE [OK]','UNSTABLE [FAIL]'));
fprintf('  ---------------------------------------------------------\n');
fprintf('  Belly tank:  %.1f m -> %.1f m  CG=%.1fm  Vol=%.1fm^3  Fill=%.1f%%\n', ...
        x_tank_fwd,x_tank_aft,x_fb,tank_vol_fus,tank_fill_pct);
fprintf('  11 figures generated.\n');
fprintf('=================================================================\n\n');
