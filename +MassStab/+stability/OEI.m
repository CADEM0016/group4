%% MassStab.stability.OEI — One Engine Inoperative check (CS-25.149)

function OEI(ADP)

V_MCG   = 72;                               % [m/s] min control speed on ground
q_MCG   = 0.5*1.225*V_MCG^2;
y_eng   = 0.38*ADP.Span/2;                 % inboard engine (engine.m line 16)
N_OEI   = ADP.T_per_eng_kN*1e3 * y_eng;   % yawing moment [N.m]
L_vt    = ADP.VtpPos - ADP.WingPos;
S_vt_min = N_OEI / (q_MCG * 0.60 * L_vt);

fprintf('\n  OEI: N=%.1fkN.m  S_vt_min=%.2fm2  actual=%.2fm2  ', ...
    N_OEI/1e3, S_vt_min, ADP.VtpArea);
if ADP.VtpArea >= S_vt_min
    fprintf('[PASS]\n');
else
    fprintf('[FAIL]\n');
end
end
