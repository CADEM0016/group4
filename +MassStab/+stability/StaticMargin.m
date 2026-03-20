%% MassStab.stability.StaticMargin — Neutral point & static margins
%  Datcom-style, consistent with AeroPolar.m Beta/e framework

function stab = StaticMargin(ADP, cg)

wg  = MassStab.geom.Wing(ADP);
M_c = ADP.TLAR.M_c;
AR  = ADP.Span^2/ADP.WingArea;
b2  = max(0.01, 1-M_c^2);

% Lift-curve slopes  (Helmbold formula, AeroPolar.m style)
CLa_w  = 2*pi*AR/(2+sqrt(4+AR^2*b2*(1+tand(wg.SweepQtrChord)^2/b2)));
CLa_ht = 2*pi*5/(2+sqrt(4+5^2*b2));

% Fuselage destabilising (Munk)
L_f   = ADP.CockpitLength + ADP.CabinLength + ADP.CabinRadius*1.48;
dCM   = 1.3*(2*ADP.CabinRadius/ADP.Span)^2*(L_f^2*2*ADP.CabinRadius)/(ADP.WingArea*cg.MAC);

% Downwash + HTP contribution
d_eps = 2*CLa_w/(pi*AR);
L_ht  = ADP.HtpPos - ADP.WingPos;
eta_h = 0.90;
x_np  = 24.0 - (dCM/CLa_w)*100 + ...
        eta_h*(CLa_ht/CLa_w)*(1-d_eps)*(ADP.HtpArea/ADP.WingArea)*(L_ht/cg.MAC)*100;

% Tail volume check  (empenage.m)
V_HT = ADP.HtpArea*L_ht/(ADP.WingArea*cg.MAC);
V_VT = ADP.VtpArea*(ADP.VtpPos-ADP.WingPos)/(ADP.WingArea*ADP.Span);

stab.NP_pct    = x_np;
stab.SM_MTOM   = x_np - cg.MTOM_pct;
stab.SM_MC     = x_np - cg.MC_pct;
stab.SM_MLW    = x_np - cg.MLW_pct;
stab.V_HT      = V_HT;
stab.V_VT      = V_VT;
stab.CLa_w     = CLa_w;
stab.CLa_ht    = CLa_ht;

fprintf('\n  Neutral Point = %.1f%% MAC\n', x_np);
fprintf('  V_HT=%.4f  V_VT=%.4f\n', V_HT, V_VT);
fprintf('  %-14s  %5.1f%%MAC  SM=%5.1f%%  %s\n','MTOM',    cg.MTOM_pct, stab.SM_MTOM, lbl(stab.SM_MTOM));
fprintf('  %-14s  %5.1f%%MAC  SM=%5.1f%%  %s\n','Mid-Cruise',cg.MC_pct, stab.SM_MC,   lbl(stab.SM_MC));
fprintf('  %-14s  %5.1f%%MAC  SM=%5.1f%%  %s\n','MLW',      cg.MLW_pct, stab.SM_MLW,  lbl(stab.SM_MLW));

if all([stab.SM_MTOM stab.SM_MC stab.SM_MLW]>=5)
    fprintf('  [PASS] All SM >= 5%% MAC  (CS-25)\n');
else
    fprintf('  [FAIL] SM < 5%% MAC in at least one phase\n');
end
end

function s=lbl(sm)
    if sm<5,s='FAIL'; elseif sm<10,s='MARGINAL'; elseif sm<=30,s='GOOD'; else,s='OK'; end
end
