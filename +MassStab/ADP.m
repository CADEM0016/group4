%% MassStab.ADP — Default aircraft design parameters
%  All values from +B777/ADP.m, +B747/ADP.m, Master Parameters table
%  CADEM0016 | GDP Group 3

function ADP = ADP()

% Mass fractions  (B777.ADP / B747.ADP)
ADP.MTOM        = 530000;           % [kg]
ADP.OEM         = 200000;           % [kg]
ADP.Mf_Fuel     = 180000/530000;    % [-]
ADP.Mf_TOC      = 0.97;             % [-]
ADP.Mf_Ldg      = 0.70;             % [-]
ADP.Mf_res      = 0.038;            % [-]

% Constraints  (ADP.m)
ADP.ThrustToWeightRatio = 0.31;
ADP.WingLoading         = 883;      % [kg/m^2]

% Wing  (ADP.m + Size_747_Custom.m)
ADP.Span        = 71.0;             % [m]
ADP.WingArea    = 600;              % [m^2]
ADP.KinkPos     = 7;                % [m]
ADP.WingPos     = 30;               % [m]
ADP.Mstar       = 0.855;            % [-]
ADP.eta_fold    = 0.80;             % [-]  fold hinge station
ADP.b_taxi      = 65.0;             % [m]  Code E taxi span

% Empennage  (ADP.m + CG_Mass_estimations.docx)
ADP.HtpPos      = 68;               % [m]
ADP.VtpPos      = 65;               % [m]
ADP.V_HT        = 0.9;              % [-]
ADP.V_VT        = 0.07;             % [-]
ADP.HtpArea     = 126.47;           % [m^2]
ADP.VtpArea     = 85.09;            % [m^2]

% Fuselage  (ADP.m)
ADP.CockpitLength = 8;              % [m]
ADP.CabinRadius   = 3.25;           % [m]
ADP.CabinLength   = 76.3 - 8 - 3.25*2*1.48; % [m]

% Aerodynamics  (ADP.m)
ADP.CD0         = 0.0171;
ADP.e           = 0.810;
ADP.Cl_max      = 1.5;

% Propulsion  (engine.m + Master Params)
ADP.N_eng           = 4;
ADP.m_eng_each      = 7000;         % [kg]
ADP.T_per_eng_kN    = 400;          % [kN]

% Landing gear  (landingGear.m)
ADP.L_main_m    = 5.0;              % [m]
ADP.L_nose_m    = 3.6;              % [m]

% TLAR  (cast.TLAR.B777F + Size_747_Custom.m)
ADP.TLAR.M_c        = 0.85;
ADP.TLAR.Alt_cruise = 35000/3.28084;% [m]
ADP.TLAR.Payload    = 150000;       % [kg]
ADP.TLAR.Range      = 12200e3;      % [m]
ADP.TLAR.Crew       = 4;
ADP.TLAR.CrewMass   = (80+10)*4;    % [kg]
end
