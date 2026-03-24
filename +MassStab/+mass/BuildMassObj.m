% Build the component mass array in cast.MassObj format
%
% Each entry has a Name, a mass m [kg], and a longitudinal position X [m]
% measured from the nose datum. Lateral position is zero (planform view).
% Arm positions follow the conventions in BuildGeometry.m and engine.m.

function massObj = BuildMassObj(ADP, CIII)

w     = MassStab.geom.Wing(ADP);
L_fus = ADP.CockpitLength + ADP.CabinLength + ADP.CabinRadius * 1.48;

% Key longitudinal positions
x_engine     = ADP.WingPos - 0.75 * w.MAC;             % engines forward of wing AC
x_htp        = ADP.HtpPos  + w.c_root * 0.25;          % HTP quarter-chord
x_vtp        = ADP.VtpPos  + w.c_root * 0.25;          % VTP quarter-chord
x_gear       = ADP.WingPos + w.MAC * 0.40;             % main gear aft of wing box
x_payload    = ADP.CockpitLength + ADP.CabinLength/2;  % cargo centroid
x_fuel_wing  = ADP.WingPos + w.MAC * 0.15;             % wing tank centroid
x_fuel_belly = ADP.WingPos + w.MAC * 0.05;             % belly tank centroid (slightly fwd)

% Fuel split: 2/3 in wing tanks, 1/3 in belly tank (CG management strategy)
W_fuel_wing  = 0.667 * ADP.MTOM * ADP.Mf_Fuel;
W_fuel_belly = 0.333 * ADP.MTOM * ADP.Mf_Fuel;

% Nacelle mass per engine from Class II propulsion estimate
W_nacelle_each = CIII.W_prop / ADP.N_eng - ADP.m_eng_each;

% Engine lateral positions: inboard at 38% semi-span, outboard at 68%
y_in  =  0.38 * ADP.Span/2;
y_out =  0.68 * ADP.Span/2;

massObj = [
    entry('Wing',         CIII.W_wing,         [ADP.WingPos;  0      ])
    entry('Fuselage',     CIII.W_fus,          [L_fus/2;      0      ])
    entry('Systems',      CIII.W_sys,          [L_fus/2;      0      ])
    entry('Fuel Systems', CIII.W_fuelsys,      [L_fus/2;      0      ])
    entry('HTP',          CIII.W_ht,           [x_htp;        0      ])
    entry('VTP',          CIII.W_vt,           [x_vtp;        0      ])
    entry('Landing Gear', CIII.W_lg,           [x_gear;       0      ])
    entry('Engine R In',  ADP.m_eng_each,      [x_engine;     y_in   ])
    entry('Engine R Out', ADP.m_eng_each,      [x_engine;     y_out  ])
    entry('Engine L In',  ADP.m_eng_each,      [x_engine;    -y_in   ])
    entry('Engine L Out', ADP.m_eng_each,      [x_engine;    -y_out  ])
    entry('Nacelles',     ADP.N_eng*W_nacelle_each, [x_engine; 0     ])
    entry('Operators',    CIII.W_oper,         [ADP.CockpitLength; 0 ])
    entry('Systems Misc', CIII.W_ballast,      [ADP.WingPos;  0      ])
    entry('Fuel Wing',    W_fuel_wing,         [x_fuel_wing;  0      ])
    entry('Fuel Belly',   W_fuel_belly,        [x_fuel_belly; 0      ])
    entry('Payload',      ADP.TLAR.Payload,    [x_payload;    0      ])
];

fprintf('\n%-16s  %8s  %6s\n', 'Component', 'Mass [t]', 'x [m]');
fprintf('%s\n', repmat('-',1,36));
for k = 1:numel(massObj)
    fprintf('%-16s  %8.2f  %6.1f\n', massObj(k).Name, massObj(k).m/1e3, massObj(k).X(1));
end
fprintf('%s\n', repmat('-',1,36));
fprintf('%-16s  %8.2f\n', 'Total', sum([massObj.m])/1e3);
end


function obj = entry(name, mass, X)
obj.Name = name;
obj.m    = mass;
obj.X    = X;
end
