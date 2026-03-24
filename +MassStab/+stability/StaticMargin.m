% Static margin and neutral point estimation
%
% The neutral point is the CG location at which the aircraft is neutrally
% stable (SM = 0).  It is computed from three contributions:
%   1. Wing aerodynamic centre          (destabilising in pitch)
%   2. Fuselage Munk moment             (destabilising in pitch)
%   3. Horizontal tail restoring moment (stabilising in pitch)
%
% Static margin  SM = x_NP - x_CG  expressed as % MAC
% CS-25 requires SM >= 5% MAC at all loading conditions.
%
% Tail volume coefficients are cross-checked against ADP values.

function stab = StaticMargin(ADP, cg)

w   = MassStab.geom.Wing(ADP);
AR  = ADP.Span^2 / ADP.WingArea;
M_c = ADP.TLAR.M_c;

% Prandtl-Glauert compressibility factor
beta = sqrt(max(0.01, 1 - M_c^2));

% Wing lift-curve slope  —  Helmbold equation (subsonic, swept wing)
CLa_wing = 2*pi*AR / (2 + sqrt(4 + (AR*beta)^2 * (1 + tand(w.sweep_qc)^2/beta^2)));

% HTP lift-curve slope  (AR_ht = 5 from empenage.m)
CLa_htp  = 2*pi*5  / (2 + sqrt(4 + (5*beta)^2));

% Fuselage destabilising contribution  —  Munk moment formula
L_fus     = ADP.CockpitLength + ADP.CabinLength + ADP.CabinRadius*1.48;
dCM_da_fus = 1.3 * (2*ADP.CabinRadius / ADP.Span)^2 ...
           * (L_fus^2 * 2*ADP.CabinRadius) / (ADP.WingArea * cg.MAC);

% Downwash gradient at the HTP  (finite-wing approximation)
downwash_grad = 2 * CLa_wing / (pi * AR);

% HTP moment arm and efficiency factor
L_htp  = ADP.HtpPos - ADP.WingPos;
eta_htp = 0.90;   % HTP operates in wing downwash, reducing its effective q

% Neutral point location in % MAC (measured from LE of MAC)
% Wing AC is assumed at 24% MAC for a swept transport wing
x_ac_wing_pct = 24.0;
x_NP_pct = x_ac_wing_pct                                               ...
    - (dCM_da_fus / CLa_wing) * 100                                    ...   % fuselage term
    + eta_htp * (CLa_htp / CLa_wing) * (1 - downwash_grad)            ...   % HTP term
    * (ADP.HtpArea / ADP.WingArea) * (L_htp / cg.MAC) * 100;

SM_MTOM = x_NP_pct - cg.MTOM_pct;
SM_MC   = x_NP_pct - cg.MC_pct;
SM_MLW  = x_NP_pct - cg.MLW_pct;

% Tail volume coefficients  (cross-check against ADP.V_HT / ADP.V_VT)
V_HT = ADP.HtpArea * L_htp                          / (ADP.WingArea * cg.MAC);
V_VT = ADP.VtpArea * (ADP.VtpPos - ADP.WingPos)     / (ADP.WingArea * ADP.Span);

stab.NP_pct  = x_NP_pct;
stab.SM_MTOM = SM_MTOM;
stab.SM_MC   = SM_MC;
stab.SM_MLW  = SM_MLW;
stab.V_HT    = V_HT;
stab.V_VT    = V_VT;
stab.CLa_w   = CLa_wing;
stab.CLa_ht  = CLa_htp;

fprintf('\nNeutral Point = %.1f%% MAC\n', x_NP_pct);
fprintf('V_HT = %.4f  (ADP target %.4f)\n', V_HT, ADP.V_HT);
fprintf('V_VT = %.4f  (ADP target %.4f)\n', V_VT, ADP.V_VT);

fprintf('\n%-16s  %9s  %9s\n', 'Condition', 'CG [%%MAC]', 'SM [%%MAC]');
fprintf('%s\n', repmat('-',1,38));
fprintf('%-16s  %9.1f  %9.1f\n', 'MTOM',        cg.MTOM_pct, SM_MTOM);
fprintf('%-16s  %9.1f  %9.1f\n', 'Mid-Cruise',  cg.MC_pct,   SM_MC);
fprintf('%-16s  %9.1f  %9.1f\n', 'MLW',         cg.MLW_pct,  SM_MLW);

if all([SM_MTOM SM_MC SM_MLW] >= 5)
    fprintf('CS-25 check: PASS  (all SM >= 5%% MAC)\n');
else
    fprintf('CS-25 check: FAIL  (at least one phase SM < 5%% MAC)\n');
end
end
