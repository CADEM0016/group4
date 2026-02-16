%%%%%%%%%%% CONSTANTS %%%%%%%%%%%%%%
hf = 40000; % height in feet 
m = 0.3048; % meter constant for feet trnaslation
h = hf*m; % height of cruise (m)
weight  = (530 *1000)*9.81; % weight of the aircraft amx payload (N)
Mach  = 0.85;
y = 1.4; % gas speific heat constant 
R = 287; % air constant
L = 8.33; % length of t he airfoil 1 for the moment cause is for xfoil
S = 600; % Wing Area of the 747-8f (m^2) 
b = 71; % wingspan in meters 

%%%%%%%%%% working out Reynolds numbers %%%%%%%%%%
[T,a,P,rho,nu,mu] = atmosisa(h);

v = Mach*sqrt(y*T*R); % Velocity translation fromthe mah number (m/s)

Re  =  (v*L)/nu

%%%%%%%%%%% Aspect Ratio %%%%%%%%%%%

AR = b^2/S;

%%%%%%%%%%%% Oswalds Efficiency %%%%%%%%%
Q = 1.05; P = 0.007;
e = 1/(Q+P*pi*AR); % estimate of oswald efficency factor

fprintf('\n=== AERODYNAMIC PARAMETERS ===\n');
fprintf('AR = %.2f\n', AR);
fprintf('e = %.3f\n', e);

%%%%%%%%%%%%% CD0 COMPONENT BREAKDOWN %%%%%%%%%%%%

%% 1. WING DRAG (from XFOIL at M=0.85)
cd_airfoil_M085 = 0.0049;  % From XFOIL RAE2882, M=0.85, Re=44.3M
CD0_wing = cd_airfoil_M085;  % 2D airfoil value

fprintf('\n--- CD0 Components ---\n');
fprintf('CD0_wing = %.6f\n', CD0_wing);

%% 2. FUSELAGE DRAG
% Fuselage geometry
d_fus = 6.5;   % diameter [m]
l_fus = 76.3;  % length [m]
fineness_ratio = l_fus/d_fus;

% Reynolds number
Re_fus = rho * v * l_fus / mu;

% Skin friction (Schlichting formula)
Cf_fus = 0.455 / (log10(Re_fus))^2.58;

% Form factor (pressure drag on body)
FF_fus = 1 + 60/(fineness_ratio^3) + fineness_ratio/400;

% Wetted area
S_wet_fus = pi * d_fus * l_fus;

% Fuselage CD0
CD0_fus = Cf_fus * FF_fus * (S_wet_fus/S);

fprintf('CD0_fuselage = %.6f [Re=%.2e, FF=%.3f]\n', CD0_fus, Re_fus, FF_fus);

%% 3. HORIZONTAL TAIL DRAG
V_HT = 0.9;  % Horizontal tail volume coefficient
MAC = sqrt(S/AR);
l_HT = 38.0;  % HT moment arm [m]

% Calculate tail area
S_HT = V_HT * S * MAC / l_HT;

% Tail parameters
AR_HT = 5.0;
c_HT = sqrt(S_HT / AR_HT);
Re_HT = rho * v * c_HT / mu;
Cf_HT = 0.455 / (log10(Re_HT))^2.58;
FF_HT = 1.28;
S_wet_HT = 2.1 * S_HT;

CD0_HT = Cf_HT * FF_HT * (S_wet_HT / S);

fprintf('CD0_HT = %.6f [S_HT=%.1f m²]\n', CD0_HT, S_HT);

%% 4. VERTICAL TAIL DRAG
V_VT = 0.07;  % Vertical tail volume coefficient
l_VT = 35.0;  % VT moment arm [m]

S_VT = V_VT * S * b / l_VT;

AR_VT = 1.5;
c_VT = sqrt(S_VT / AR_VT);
Re_VT = rho * v * c_VT / mu;
Cf_VT = 0.455 / (log10(Re_VT))^2.58;
FF_VT = 1.30;
S_wet_VT = 2.1 * S_VT;

CD0_VT = Cf_VT * FF_VT * (S_wet_VT / S);

fprintf('CD0_VT = %.6f [S_VT=%.1f m²]\n', CD0_VT, S_VT);

%% 5. NACELLES AND MISC
CD0_nacelles = 0.0030;
CD0_misc = 0.0020;

fprintf('CD0_nacelles = %.6f\n', CD0_nacelles);
fprintf('CD0_misc = %.6f\n', CD0_misc);

%% TOTAL CD0
CD0 = CD0_wing + CD0_fus + CD0_HT + CD0_VT + CD0_nacelles + CD0_misc;

fprintf('\n--- TOTAL CD0 = %.6f ---\n', CD0);

%%%%%%%%%% Working out the weight vs lift %%%%%%%%%

Beta = 1/(pi*AR*e);
CL_needed = (2*weight)/(rho*v^2*S); % This is the cl need for the cruise

fprintf('\n=== CRUISE PERFORMANCE ===\n');
fprintf('CL_needed = %.4f\n', CL_needed);
fprintf('Beta = %.6f\n', Beta);

% Induced drag
CD_induced = Beta*CL_needed^2;
fprintf('CD_induced = %.6f\n', CD_induced);

% Total drag
CD = CD0 + CD_induced;
fprintf('CD_total = %.6f\n', CD);

% Lift-to-drag ratio
L_D = CL_needed/CD;
fprintf('L/D = %.2f\n', L_D);

% Drag force
Drag = 0.5 * rho * v^2 * S * CD;
fprintf('\nDrag force = %.0f N\n', Drag);
fprintf('Required thrust = %.0f N\n', Drag);
