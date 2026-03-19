%% MassStab.mass.Estimate — Class I / II / II.5 OEW estimation
%  Equations sourced directly from Group 4 codebase:
%  Wing    -> +B747/+geom/wing.m      (Raymer)
%  Fus     -> +B747/+geom/fuselage.m  (Raymer)
%  Emp     -> +B747/+geom/empenage.m  (Gudmundsson 6-49)
%  LG      -> +B777/+geom/landingGear.m (Raymer)
%  Engine  -> +B777/+geom/engine.m

function [CI, CII, CIII] = Estimate(ADP)

SI_ft = 3.28084;  SI_lb = 2.20462;
g     = 9.80665;
n_z   = 2.5*1.5;                      % ultimate load (wing.m)

wgeom = MassStab.geom.Wing(ADP);      % shared geometry
[rho_c, a_c] = MassStab.geom.Atmos(ADP.TLAR.Alt_cruise);
q_c = 0.5*rho_c*(ADP.TLAR.M_c*a_c)^2;

L_f = ADP.CockpitLength + ADP.CabinLength + ADP.CabinRadius*1.48;
W   = ADP.MTOM;

%% ---- CLASS I  (Raymer Table 15.2 statistical fractions) ----
CI.W_wing  = 0.0440*W^0.758*(ADP.Span^2/ADP.WingArea)^0.6*(1+0.05*ADP.eta_fold);
CI.W_fus   = 0.328*(L_f*ADP.CabinRadius*2)^0.5*W^0.5;
CI.W_ht    = 0.0379*ADP.HtpArea^0.639*W^0.426;
CI.W_vt    = 0.0726*ADP.VtpArea^0.773*W^0.217;
CI.W_lg    = 0.0440*W;
CI.W_prop  = ADP.N_eng*ADP.m_eng_each*1.35;
CI.W_sys   = 0.0900*W;
CI.W_oper  = ADP.TLAR.CrewMass + ADP.TLAR.Crew*140;
CI.OEW     = CI.W_wing+CI.W_fus+CI.W_ht+CI.W_vt+CI.W_lg+CI.W_prop+CI.W_sys+CI.W_oper;

%% ---- CLASS II  (semi-empirical, exact Group 4 equations) ----
% Wing  (wing.m lines 40-53)
b_ft = ADP.Span*SI_ft;  S_ft2 = ADP.WingArea*SI_ft^2;
t_ft = 0.15*wgeom.c_root*SI_ft;  cL = cosd(wgeom.sweepHalf);
Wdg  = W*ADP.Mf_TOC*SI_lb;
CII.W_wing = (0.00125*Wdg*(b_ft/cL)^0.75*(1+sqrt(6.3*cL/b_ft))*n_z^0.55 * ...
              (b_ft*S_ft2/(t_ft*Wdg*cL))^0.3)/SI_lb * (1+0.05*ADP.eta_fold);

% Fuselage  (fuselage.m lines 28-48)
K_ws = 0.75*((1+2*wgeom.taper)/(1+wgeom.taper))*(b_ft/L_f)*tand(wgeom.SweepQtrChord);
D_ft = 2*ADP.CabinRadius*SI_ft;
S_f  = pi*D_ft*(ADP.CabinLength*SI_ft) + pi*(ADP.CabinLength*SI_ft)*(ADP.CabinRadius*SI_ft) ...
       + pi*(1.48*ADP.CabinRadius*SI_ft)*(ADP.CabinRadius*SI_ft);
W_fus_lb = 0.3280*1.12*1.12*sqrt(Wdg*n_z)*L_f^0.25*S_f^0.302*(1+K_ws)^0.04*(L_f/D_ft)^0.10;
CII.W_fus = W_fus_lb/SI_lb * 1.5;                % fuselage.m *1.5

% Systems + fuel system  (fuselage.m lines 51-56)
CII.W_sys     = (270*(2*ADP.CabinRadius)+150)*L_f/g*2;
V_t_L         = (W*ADP.Mf_Fuel/804)*1000;
CII.W_fuelsys = 36.3*(ADP.N_eng+3-1)+4.366*sqrt(3)*V_t_L^(1/3);

% Empennage  (empenage.m, Gudmundsson 6-49)
AR_ht=5; AR_vt=3.1; tcr=0.15; tct=0.12; tr=wgeom.taper; sw=wgeom.SweepQtrChord;
m_HT_lb = 0.016*(1.5*2.5*Wdg)^0.414*(SI_lb/SI_ft^2*q_c)^0.168 * ...
          (ADP.HtpArea*SI_ft^2)^0.896*(100*(tcr+tct)/2/cosd(sw))^-0.12 * ...
          (AR_ht/cosd(sw)^2)^0.043*tr^-0.02;
CII.W_ht = m_HT_lb/SI_lb;

m_VT_lb = 0.073*(1.5*2.5*Wdg)^0.376*(SI_lb/SI_ft^2*q_c)^0.122 * ...
          (ADP.VtpArea*SI_ft^2)^0.873*(100*(tcr+tct)/2/cosd(sw))^-0.49 * ...
          (AR_vt/cosd(sw)^2)^0.357*tr^0.039;
CII.W_vt = m_VT_lb/SI_lb;

% Landing gear  (landingGear.m)
M_lb = ADP.Mf_Ldg*W*SI_lb;
CII.W_lg   = (0.125*(1.5*M_lb)^0.566*(ADP.L_nose_m*SI_ft)^0.845 + ...
              0.095*(1.5*M_lb)^0.768*(ADP.L_main_m*SI_ft)^0.409)/SI_lb;

% Propulsion  (engine.m)
m_inst = (1.1*(2.575*(ADP.m_eng_each*SI_lb)^0.922)/SI_lb - ADP.m_eng_each);
CII.W_prop = ADP.N_eng*(ADP.m_eng_each + m_inst);
CII.W_oper = ADP.TLAR.CrewMass + ADP.TLAR.Crew*140;

CII.OEW = CII.W_wing+CII.W_fus+CII.W_ht+CII.W_vt+CII.W_lg + ...
          CII.W_prop+CII.W_sys+CII.W_fuelsys+CII.W_oper;
CII.W_ballast = max(0, ADP.OEM - CII.OEW);
CII.OEW_total = CII.OEW + CII.W_ballast;

%% ---- CLASS II.5  (physics-based) ----
rho_al=2780; sig_al=503e6;

% Wing: bending material index  (Torenbeek §9.3)
M_bm   = 2.5*W*g*ADP.Span/8*0.85;
h_box  = 0.55*0.12*wgeom.c_root;
A_cap  = M_bm/(sig_al*h_box/2);
W_fold = 450*(1-ADP.eta_fold)*ADP.Span;
CIII.W_wing = rho_al*2*A_cap*(ADP.Span/2)*1.15*1.30 + W_fold;

% Fuselage: pressure vessel + beam  (Torenbeek §8.3)
t_skin = 8*6894.76*ADP.CabinRadius/(sig_al/1.5);
CIII.W_fus = rho_al*pi*2*ADP.CabinRadius*L_f*t_skin + ...
             rho_al*2*(2.5*W*g*L_f/8/(sig_al/1.5*ADP.CabinRadius))*L_f*1.10 + ...
             35*L_f*2*ADP.CabinRadius;

% Empennage: structural loads
b_ht = sqrt(AR_ht*ADP.HtpArea);
c_ht_r = ADP.HtpArea/((1+tr)/2*b_ht);
M_ht = 1.1*q_c*0.30*ADP.HtpArea*b_ht/4;
CIII.W_ht = rho_al*(M_ht/(sig_al*0.45*c_ht_r*tcr))*b_ht*1.5*1.30;

b_vt = sqrt(AR_vt*ADP.VtpArea);
c_vt_r = ADP.VtpArea/((1+tr)/2*b_vt);
M_vt = 1.25*ADP.T_per_eng_kN*1e3*0.38*ADP.Span/2;
CIII.W_vt = rho_al*(M_vt/(sig_al*0.45*c_vt_r*tcr))*b_vt*1.5*1.30;

% Retain Class II for LG / prop / systems
CIII.W_lg       = CII.W_lg;
CIII.W_prop     = CII.W_prop;
CIII.W_sys      = CII.W_sys;
CIII.W_fuelsys  = CII.W_fuelsys;
CIII.W_oper     = CII.W_oper;
CIII.OEW        = CIII.W_wing+CIII.W_fus+CIII.W_ht+CIII.W_vt+CIII.W_lg + ...
                  CIII.W_prop+CIII.W_sys+CIII.W_fuelsys+CIII.W_oper;
CIII.W_ballast  = max(0, ADP.OEM - CIII.OEW);
CIII.OEW_total  = CIII.OEW + CIII.W_ballast;

% Print summary
print_table('CLASS I',   CI,   CI.OEW,        ADP.OEM);
print_table('CLASS II',  CII,  CII.OEW_total, ADP.OEM);
print_table('CLASS II.5',CIII, CIII.OEW_total,ADP.OEM);
end

function print_table(label, S, total, target)
fprintf('\n  %s  (total=%.1ft, err=%+.1f%%)\n', label, total/1e3, (total-target)/target*100);
flds = {'W_wing','W_fus','W_ht','W_vt','W_lg','W_prop','W_sys'};
nms  = {'Wing','Fuselage','HTP','VTP','LG','Propulsion','Systems'};
for k=1:7
    if isfield(S,flds{k})
        fprintf('    %-14s %7.1f t\n', nms{k}, S.(flds{k})/1e3);
    end
end
end
