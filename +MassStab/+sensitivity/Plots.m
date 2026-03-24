% Sensitivity studies and all figures for the Mass & Stability discipline
%
% Figure 1  OEW component breakdown across Class I / II / II.5
% Figure 2  CG envelope  (potato diagram) — two loading sequences
% Figure 3  Static margin sensitivity to HTP area
% Figure 4  Wing structural mass vs wingspan
% Figure 5  OEW vs MTOM trade
% Figure 6  CG migration during fuel burn (belly-first strategy)
% Figure 7  OEW component fractions as pie charts

function Plots(ADP, CI, CII, CIII, cg, stab)

w     = MassStab.geom.Wing(ADP);
L_fus = ADP.CockpitLength + ADP.CabinLength + ADP.CabinRadius * 1.48;
pct   = @(x) (x - cg.x_LE_MAC) / cg.MAC * 100;

[rho_c, a_c] = MassStab.geom.Atmos(ADP.TLAR.Alt_cruise);
q_cruise = 0.5 * rho_c * (ADP.TLAR.M_c * a_c)^2;

W_fuel_wing  = 0.667 * ADP.MTOM * ADP.Mf_Fuel;
W_fuel_belly = 0.333 * ADP.MTOM * ADP.Mf_Fuel;
x_fuel_wing  = ADP.WingPos + w.MAC * 0.15;
x_fuel_belly = ADP.WingPos + w.MAC * 0.05;
x_payload    = ADP.CockpitLength + ADP.CabinLength / 2;

% ---- Sensitivity sweep 1: NP and SM vs HTP area ----------------------
% Recalculates neutral point for a range of HTP areas while holding
% everything else fixed.  Shows minimum HTP area for SM >= 5%.
S_ht_range   = linspace(70, 200, 60);
AR           = ADP.Span^2 / ADP.WingArea;
beta         = sqrt(1 - ADP.TLAR.M_c^2);
CLa_w        = stab.CLa_w;
CLa_ht       = stab.CLa_ht;
downwash     = 2 * CLa_w / (pi * AR);
L_htp        = ADP.HtpPos - ADP.WingPos;
dCM_fus      = 1.3*(2*ADP.CabinRadius/ADP.Span)^2 * (L_fus^2*2*ADP.CabinRadius) ...
               / (ADP.WingArea * cg.MAC);

NP_vs_Sht = arrayfun(@(S) ...
    24 - (dCM_fus/CLa_w)*100 + 0.9*(CLa_ht/CLa_w)*(1-downwash)*(S/ADP.WingArea)*(L_htp/cg.MAC)*100, ...
    S_ht_range);

% ---- Sensitivity sweep 2: wing structural mass vs span ---------------
% Uses the Class II.5 bending material index.  Shows the mass jump from
% the folding mechanism penalty as span increases beyond taxi limit.
rho_al   = 2780;
sigma_al = 503e6;
b_range  = linspace(55, 90, 60);

Wwing_vs_b = arrayfun(@(b) ( ...
    rho_al * 2 * (2.5*ADP.MTOM*9.81*(b/2)/2*0.85 / (sigma_al*0.55*0.12*w.c_root/2)) ...
    * (b/2)*1.15 * 1.30 + 450*(1-ADP.eta_fold)*b ) / 1e3, b_range);

% ---- Sensitivity sweep 3: CG position during fuel burn ---------------
% Models belly-first burn strategy from 0% to 100% fuel consumed.
fb_pct = linspace(0, 100, 120);
cg_burn = arrayfun(@(f) cg_during_burn( ...
    f/100 * ADP.MTOM*ADP.Mf_Fuel, ...
    W_fuel_wing, W_fuel_belly, ...
    ADP.OEM, cg.OEW_m, ...
    ADP.TLAR.Payload, x_payload, ...
    x_fuel_wing, x_fuel_belly, ...
    cg.x_LE_MAC, cg.MAC), fb_pct);

% ---- Sensitivity sweep 4: OEW vs MTOM --------------------------------
MTOM_range  = linspace(300e3, 650e3, 60);
OEW_I_range = arrayfun(@(W) ...
    0.0440*W^0.758*(ADP.Span^2/ADP.WingArea)^0.6 + ...
    0.328*(L_fus*2*ADP.CabinRadius)^0.5*W^0.5 + 0.044*W + 0.090*W, MTOM_range);


% ======================================================================
%  FIGURE 1  —  OEW component breakdown
% ======================================================================
comp_labels = {'Wing','Fuselage','HTP','VTP','LG','Propulsion','Systems'};
comp_fields = {'W_wing','W_fus','W_ht','W_vt','W_lg','W_prop','W_sys'};
get_vals    = @(S) cellfun(@(f) S.(f)/1e3, comp_fields);

figure('Name','Fig 1 — OEW Breakdown');
X  = reordercats(categorical(comp_labels), comp_labels);
bh = bar(X, [get_vals(CI); get_vals(CII); get_vals(CIII)]', 'grouped');
bh(1).FaceColor = [0.20 0.40 0.80];
bh(2).FaceColor = [0.90 0.50 0.10];
bh(3).FaceColor = [0.20 0.70 0.30];
yline(ADP.OEM/1e3, 'r--', 'LineWidth', 2, 'Label', 'Target OEW');
ylabel('Mass [t]');
title('OEW Component Breakdown — Class I / II / II.5');
legend({'Class I','Class II','Class II.5'}, 'Location', 'northeast');
grid on;

% ======================================================================
%  FIGURE 2  —  CG envelope (potato diagram)
%  Two loading sequences: (A) payload-first then fuel, (B) fuel-first then payload.
%  The convex hull of both sequences forms the allowable CG envelope.
% ======================================================================
figure('Name','Fig 2 — CG Envelope');

[W_seq_A, cg_seq_A] = loading_sequence( ...
    ADP.OEM, cg.OEW_m, ...
    ADP.TLAR.Payload, x_payload, ...
    W_fuel_wing, x_fuel_wing, W_fuel_belly, x_fuel_belly, pct);

[W_seq_B, cg_seq_B] = loading_sequence( ...
    ADP.OEM, cg.OEW_m, ...
    W_fuel_wing, x_fuel_wing, W_fuel_belly, x_fuel_belly, ...
    ADP.TLAR.Payload, x_payload, pct);

fill_envelope([cg_seq_A cg_seq_B], [W_seq_A W_seq_B]);
hold on;
plot(cg_seq_A, W_seq_A/1e3, 'b-o', 'LineWidth', 2, 'DisplayName', 'Payload \rightarrow Fuel');
plot(cg_seq_B, W_seq_B/1e3, 'r-s', 'LineWidth', 2, 'DisplayName', 'Fuel \rightarrow Payload');
xline(stab.NP_pct,      'k--', 'LineWidth', 2,   'Label', sprintf('NP = %.0f%%', stab.NP_pct));
xline(stab.NP_pct - 5,  'g--', 'LineWidth', 1.5, 'Label', 'SM = 5%');
xline(stab.NP_pct - 35, 'm--', 'LineWidth', 1.5, 'Label', 'SM = 35%');
plot(cg.MTOM_pct, ADP.MTOM/1e3,             'kp', 'MarkerSize', 13, 'MarkerFaceColor', 'y', 'DisplayName', 'MTOM');
plot(cg.MLW_pct,  ADP.Mf_Ldg*ADP.MTOM/1e3, 'k^', 'MarkerSize', 11, 'MarkerFaceColor', 'c', 'DisplayName', 'MLW');
xlabel('CG [% MAC]');  ylabel('Aircraft Mass [t]');
title('CG Envelope  (Potato Diagram)');
legend('Location', 'southeast');  grid on;  xlim([10 85]);

% ======================================================================
%  FIGURE 3  —  Static margin vs HTP area
%  The green band marks the acceptable SM range (5% to 35%).
% ======================================================================
figure('Name','Fig 3 — SM vs HTP Area');
plot(S_ht_range, NP_vs_Sht - cg.MTOM_pct, 'b-', 'LineWidth', 2.5);
hold on;
xline(ADP.HtpArea, 'r--', 'LineWidth', 2,   'Label', sprintf('Current  S_{HT} = %.0f m²', ADP.HtpArea));
yline(5,           'g--', 'LineWidth', 1.5, 'Label', 'SM_{min} = 5%');
yline(35,          'm--', 'LineWidth', 1.5, 'Label', 'SM_{max} = 35%');
plot(ADP.HtpArea, stab.SM_MTOM, 'kp', 'MarkerSize', 13, 'MarkerFaceColor', 'y');
xlabel('Horizontal Tail Area  S_{HT}  [m²]');
ylabel('Static Margin at MTOM  [% MAC]');
title('Static Margin Sensitivity to HTP Area');  grid on;

% ======================================================================
%  FIGURE 4  —  Wing structural mass vs wingspan
%  The step in the curve at b_taxi marks the transition where the folding
%  tip penalty begins to dominate.
% ======================================================================
figure('Name','Fig 4 — Wing Mass vs Span');
plot(b_range, Wwing_vs_b, 'b-', 'LineWidth', 2.5);
hold on;
xline(ADP.Span,   'r--', 'LineWidth', 2, 'Label', sprintf('b_{flight} = %.0f m', ADP.Span));
xline(ADP.b_taxi, 'g--', 'LineWidth', 2, 'Label', sprintf('b_{taxi} = %.0f m',  ADP.b_taxi));
plot(ADP.Span, CIII.W_wing/1e3, 'kp', 'MarkerSize', 13, 'MarkerFaceColor', 'y', 'DisplayName', 'Design point');
xlabel('Wing Span  [m]');
ylabel('Wing Structural Mass  [t]');
title('Wing Structural Mass vs Wingspan  (Class II.5)');
legend('Location', 'northwest');  grid on;

% ======================================================================
%  FIGURE 5  —  OEW vs MTOM
%  Illustrates how the three methods diverge as MTOM increases.
% ======================================================================
figure('Name','Fig 5 — OEW vs MTOM');
plot(MTOM_range/1e3, OEW_I_range/1e3, 'b--', 'LineWidth', 2,   'DisplayName', 'Class I');
hold on;
plot(MTOM_range/1e3, MTOM_range*0.47/1e3, 'r-', 'LineWidth', 2, 'DisplayName', 'Class II');
plot(ADP.MTOM/1e3, CIII.OEW_total/1e3, 'kp', 'MarkerSize', 13, 'MarkerFaceColor', 'y', ...
    'DisplayName', sprintf('Class II.5  (%.0f t)', CIII.OEW_total/1e3));
plot(348.7, 145, 'gs', 'MarkerSize', 12, 'MarkerFaceColor', 'g', 'DisplayName', 'B777F  reference');
xlabel('MTOM  [t]');  ylabel('OEW  [t]');
title('OEW vs MTOM');  legend('Location', 'northwest');  grid on;

% ======================================================================
%  FIGURE 6  —  CG migration during fuel burn
%  Belly tank depletes first, moving CG aft (reducing trim drag in cruise).
%  Wing fuel then depletes, moving CG forward (improving stability on approach).
% ======================================================================
figure('Name','Fig 6 — CG During Fuel Burn');
plot(fb_pct, cg_burn, 'b-', 'LineWidth', 2.5);
hold on;
xline(W_fuel_belly/(ADP.MTOM*ADP.Mf_Fuel)*100, 'r--', 'LineWidth', 1.5, 'Label', 'Belly empty');
yline(stab.NP_pct,      'k--', 'LineWidth', 1.5, 'Label', sprintf('NP = %.0f%%', stab.NP_pct));
yline(stab.NP_pct - 5,  'g--', 'LineWidth', 1.2);
yline(stab.NP_pct - 35, 'm--', 'LineWidth', 1.2);
xlabel('Fuel Burned  [% of total fuel]');
ylabel('CG Position  [% MAC]');
title('CG Migration — Belly-First Burn Strategy');  grid on;

% ======================================================================
%  FIGURE 7  —  OEW component fractions
% ======================================================================
figure('Name','Fig 7 — OEW Fractions');
pie_labels = {'Wing','Fuselage','HTP+VTP','LG','Propulsion','Systems'};
pie_data   = @(S) [S.W_wing, S.W_fus, S.W_ht+S.W_vt, S.W_lg, S.W_prop, S.W_sys];
subplot(1,3,1);  pie(pie_data(CI),   pie_labels);  title('Class I');
subplot(1,3,2);  pie(pie_data(CII),  pie_labels);  title('Class II');
subplot(1,3,3);  pie(pie_data(CIII), pie_labels);  title('Class II.5');
sgtitle('OEW Component Fractions');
colormap(parula(6));
end


% ======================================================================
%  LOCAL HELPER FUNCTIONS
% ======================================================================

function cg_pct = cg_during_burn(burned, Wfw, Wfb, Woew, Xoew, Wpay, Xpay, Xfw, Xfb, xLE, MAC)
% Returns CG as % MAC for a given amount of fuel burned (belly-first)
belly_remaining = max(0, Wfb - burned);
wing_remaining  = max(0, Wfw - max(0, burned - Wfb));
W_total  = Woew + Wpay + belly_remaining + wing_remaining;
moment   = Xoew*Woew + Xpay*Wpay + Xfb*belly_remaining + Xfw*wing_remaining;
cg_pct   = (moment/W_total - xLE) / MAC * 100;
end


function [W_seq, cg_seq] = loading_sequence(W0,x0, W1,x1, W2,x2, W3,x3, pct_fn)
% Builds a 6-point loading sequence adding three items in order (0.5 step each)
W_seq = [W0, W0+W1*0.5, W0+W1, W0+W1+W2*0.5, W0+W1+W2, W0+W1+W2+W3];
mom   = [W0*x0, ...
         W0*x0+W1*0.5*x1, ...
         W0*x0+W1*x1, ...
         W0*x0+W1*x1+W2*0.5*x2, ...
         W0*x0+W1*x1+W2*x2, ...
         W0*x0+W1*x1+W2*x2+W3*x3];
cg_seq = pct_fn(mom ./ W_seq);
W_seq  = W_seq / 1e3;   % convert to tonnes for plotting
end


function fill_envelope(cg_pts, W_pts)
% Draws a shaded convex hull around all CG-weight points
try
    hull = convhull(cg_pts, W_pts);
    fill(cg_pts(hull), W_pts(hull), [0.85 0.92 1.0], ...
        'EdgeColor', [0.2 0.4 0.8], 'LineWidth', 2, 'FaceAlpha', 0.35);
catch
end
end
