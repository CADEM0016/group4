% Aircraft Design Parameters  —  Group 3 concept wide-body freighter
% All values taken from Master Parameters table, +B777/ADP.m, +B747/ADP.m
% Units: kg, m, kN throughout unless noted

function ADP = ADP()

% ---- Top-level masses ------------------------------------------------
ADP.MTOM         = 530000;           % Maximum take-off mass         [kg]
ADP.OEM          = 200000;           % Operational empty mass target  [kg]
ADP.Mf_Fuel      = 180000 / 530000;  % Fuel mass fraction             [-]
ADP.Mf_TOC       = 0.97;             % Mass fraction at top of climb  [-]
ADP.Mf_Ldg       = 0.70;             % Maximum landing mass fraction  [-]
ADP.Mf_res       = 0.038;            % Reserve fuel fraction          [-]

% ---- Constraint analysis outputs -------------------------------------
ADP.ThrustToWeightRatio = 0.31;      % T/W at take-off                [-]
ADP.WingLoading         = 883;       % W/S at take-off            [kg/m²]

% ---- Wing geometry ---------------------------------------------------
ADP.Span         = 71.0;   % Flight span (folded tips deployed)       [m]
ADP.b_taxi       = 65.0;   % Taxi span (folded tips up, ICAO Code E)  [m]
ADP.WingArea     = 600;    % Reference wing area                      [m²]
ADP.KinkPos      = 7;      % Spanwise position of trailing-edge kink  [m]
ADP.WingPos      = 30;     % Wing aerodynamic centre along fuselage   [m]
ADP.Mstar        = 0.855;  % Wing technology factor (drag-divergence) [-]
ADP.eta_fold     = 0.80;   % Fold hinge at 80% semi-span              [-]

% ---- Empennage geometry and tail volume coefficients -----------------
ADP.HtpPos   = 68;      % HTP aerodynamic centre along fuselage       [m]
ADP.VtpPos   = 65;      % VTP aerodynamic centre along fuselage       [m]
ADP.V_HT     = 0.9;     % Horizontal tail volume coefficient          [-]
ADP.V_VT     = 0.07;    % Vertical tail volume coefficient            [-]
ADP.HtpArea  = 126.47;  % Horizontal tail reference area              [m²]
ADP.VtpArea  = 85.09;   % Vertical tail reference area                [m²]

% ---- Fuselage geometry -----------------------------------------------
ADP.CockpitLength = 8;           % Nose section length                [m]
ADP.CabinRadius   = 3.25;        % Fuselage outer radius (D = 6.5 m)  [m]
ADP.CabinLength   = 76.3 - 8 - 3.25*2*1.48;  % Cylindrical barrel    [m]

% ---- Aerodynamics ----------------------------------------------------
ADP.CD0    = 0.0171;   % Zero-lift drag coefficient (component build-up)
ADP.e      = 0.810;    % Oswald efficiency factor
ADP.Cl_max = 1.5;      % Maximum wing section lift coefficient

% ---- Propulsion  (4 × Rolls-Royce UltraFan class) -------------------
ADP.N_eng        = 4;     % Number of engines
ADP.m_eng_each   = 7000;  % Dry mass per engine                     [kg]
ADP.T_per_eng_kN = 400;   % Sea-level static thrust per engine       [kN]

% ---- Landing gear geometry -------------------------------------------
ADP.L_main_m = 5.0;   % Extended main gear leg length                 [m]
ADP.L_nose_m = 3.6;   % Extended nose gear leg length                 [m]

% ---- Top-level aircraft requirements (TLAR) --------------------------
ADP.TLAR.M_c        = 0.85;              % Cruise Mach number
ADP.TLAR.Alt_cruise = 35000 / 3.28084;  % Cruise altitude           [m]
ADP.TLAR.Payload    = 150000;            % Design payload            [kg]
ADP.TLAR.Range      = 12200e3;           % Design range              [m]
ADP.TLAR.Crew       = 4;                 % Flight crew + relief crew
ADP.TLAR.CrewMass   = 90 * 4;           % Crew mass (90 kg each)    [kg]
end
