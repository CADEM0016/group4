% The wing is parameterised by three spanwise sections:
%   Body section   fuselage centre-line  -->  fuselage side (R_fus)
%   Mid section    fuselage side         -->  trailing-edge kink
%   Tip section    kink                  -->  wing tip

function w = Wing(ADP)

% Quarter-chord sweep from wing technology factor and cruise Mach
sweep_qc = real(acosd(0.75 * ADP.Mstar / ADP.TLAR.M_c));

% Taper ratio of the outer panel  (empirical fit from Raymer)
taper = -0.0083 * sweep_qc + 0.4597;

R_fus  = ADP.CabinRadius;
L_mid  = ADP.KinkPos  - R_fus;        % mid-panel spanwise length   [m]
L_tip  = ADP.Span/2   - ADP.KinkPos;  % tip-panel spanwise length   [m]

% Seed estimate for kink chord, then solve for correct total area
c0     = (ADP.WingArea / ADP.Span) / (1 + taper) * ...
         (1 - (1 - taper) * ADP.KinkPos / (ADP.Span/2));
c_kink = fminsearch(@(c) (wing_area(c, L_mid, L_tip, R_fus, taper, sweep_qc) - ADP.WingArea)^2, c0);

[~, c_tip, c_root] = wing_area(c_kink, L_mid, L_tip, R_fus, taper, sweep_qc);

% Leading-edge and half-chord sweep angles from quarter-chord sweep
sweep_le   = atand((tand(sweep_qc)*L_tip + c_kink/4 - c_tip/4) / L_tip);
sweep_half = atand((tand(sweep_qc)*L_tip - c_kink/4 + c_tip/4) / L_tip);

% Standard MAC formula for a linearly tapered wing
MAC = (2/3) * c_root * (1 + taper + taper^2) / (1 + taper);

% Pack results into output struct
w.sweep_qc   = sweep_qc;
w.sweep_le   = sweep_le;
w.sweep_half = sweep_half;
w.taper      = taper;
w.c_root     = c_root;
w.c_tip      = c_tip;
w.c_kink     = c_kink;
w.MAC        = MAC;
w.x_LE_MAC   = ADP.WingPos - 0.25 * MAC;  % LE of MAC measured from nose
end


function [S, c_tip, c_root, A_body, A_mid, A_tip] = wing_area(c_kink, L_mid, L_tip, R_fus, taper, sweep_qc)
% Returns total planform area and section chords for a given kink chord

c_tip    = taper * c_kink;
sweep_le = atand((tand(sweep_qc)*L_tip + c_kink/4 - c_tip/4) / L_tip);
c_root   = c_kink + tand(sweep_le) * L_mid;

A_body = c_root * R_fus;                  % rectangular body section
A_mid  = (c_root + c_kink) / 2 * L_mid;  % trapezoidal mid section
A_tip  = (c_kink + c_tip)  / 2 * L_tip;  % trapezoidal tip section
S      = 2 * (A_body + A_mid + A_tip);    % total (both halves)
end
