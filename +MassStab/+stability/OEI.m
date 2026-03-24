% One-engine-inoperative directional control check  (CS-25.149)
%
% At the minimum control speed on the ground (V_MCG), the rudder must be
% able to counteract the yawing moment from the critical (inboard) engine.
% This sets a lower bound on the required VTP area.

function OEI(ADP)

V_MCG     = 72;   % minimum control speed on ground  [m/s]  (~140 kt)
q_ground  = 0.5 * 1.225 * V_MCG^2;   % dynamic pressure at V_MCG  [Pa]

y_critical_engine = 0.38 * ADP.Span / 2;            % inboard engine position  [m]
N_yaw_OEI         = ADP.T_per_eng_kN * 1e3 * y_critical_engine;  % yawing moment  [N.m]

L_vtp          = ADP.VtpPos - ADP.WingPos;   % VTP moment arm  [m]
CL_rudder      = 0.60;                        % rudder lift coefficient at full deflection
S_vtp_required = N_yaw_OEI / (q_ground * CL_rudder * L_vtp);

fprintf('\nOEI Check  (CS-25.149)\n');
fprintf('  Yawing moment at V_MCG  = %8.1f kN.m\n', N_yaw_OEI/1e3);
fprintf('  VTP area required       = %8.2f m2\n',   S_vtp_required);
fprintf('  VTP area actual         = %8.2f m2\n',   ADP.VtpArea);
if ADP.VtpArea >= S_vtp_required
    fprintf('  Result: PASS\n');
else
    fprintf('  Result: FAIL  —  increase VTP area by %.1f m2\n', S_vtp_required - ADP.VtpArea);
end
end
