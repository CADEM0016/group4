classdef ADP < handle
    %ADP Aircraft Design Parameters for a B747-8F
    
    properties
        TLAR
        Engine
        AeroPolar
    end

    properties
        MTOM    = 530000;   % Maximum take-off mass [kg] (updated)
        OEM     = 200000;   % Operational Empty Mass [kg]
        Mf_Ldg  = 0.70;     % maximum landing mass fraction (Estimate)
        Mf_Fuel = 0.34;     % fuel mass fraction (Estimate) % Double check this values !
        Mf_TOC  = 0.97;     % "top of climb" mass fraction  !
        Mf_res  = 0.038;     % "Reserve Fuel" mass fraction  !
    end

    % constraint Paramters
    properties
        ThrustToWeightRatio = 0.31; % Approx for 747
        WingLoading         = 883;  % Approx kg/m^2
    end

    % Aerodynamic
    properties
        % ------------------------- geometry -------------------------
        V_HT = 0.9; % Horizontal Tail Volume
        V_VT = 0.07; % Vertical tail volume

        % --------------------- aero properties ----------------------
        Cl_max = 1.5;   % airfoil max Cl for wing
        
        Delta_Cl_ld = 1;   % Extra CL during landing
        Delta_Cl_to = 0.8; % Extra CL at take-off

        CD_TO = 0.03;     % CD in ground run
        CL_TO = 0.8;      % CL during ground run        
        CD_LDG = 0.03;    % CD in ground run on landing
        CL_LDG = 0.8;     % CL during ground run on landing
        CL_cruise = 0.5;  % CL during cruise

        LD_c = 1;        % Lift to drag ratio in cruise (updated)
        LD_app = 10;      % Lift to drag ratio during landing
        CD0 = 0.0171;     % Zero-lift drag coefficent (from component buildup)
        e = 0.810;        % Oswald Efficency Factor (from Q+P formula)
    end

    % Sizing Flags
    properties
        isSizeEng = true; % whether to change engine maximum Thrust Value
        isSizeWing = true; % whether to size the wing
    end

    % Concrete properties
    properties
        Thrust;

        % planfrom specific
        Span = 71.0;        % [m] (updated)
        WingArea = 600;     % [m^2] (updated)
        KinkPos = 7;        % y position of wing kink (Estimate)
        WingPos = 30;       % Wing position along fuselage (Estimate)
        HtpPos = 68;        % HTP pos along fuselage (Estimate)
        VtpPos = 65;        % VTP pos along fuselage (Estimate)

        Mstar = 0.855;      % wing technology factor (Cruise Mach is ~0.855 for 747-8)

        % Empenage Specific
        HtpArea;
        VtpArea
    end

    % useful properties
    properties
        c_ac % mean geometric chord of main wing
        x_ac % x location of mean geometeric chord
        c_ach % mean geometric chord of HTP
        c_acv % mean geometric chord of VTP
    end

    % fuselage properties
    properties
        CockpitLength = 8;     % Adjusted for 747
        CabinRadius = 3.25;    % Radius (6.5m diameter)
        CabinLength = 76.3 - 8 - 3.25*2*1.48; % Approx length based on total 76.3m
    end

    methods
        function out = AR(obj)
            out = obj.Span^2/obj.WingArea;
        end

        function [CD0_total, breakdown] = CalculateCD0(obj, h, Mach)
            % Calculate zero-lift drag coefficient using component buildup
            % Based on cruise_basic_1.m logic
            
            if nargin < 2
                h = 40000 * 0.3048; % 40,000 ft in meters
                Mach = 0.85;
            end
            
            % Atmospheric properties
            [T, a, P, rho] = atmosisa(h);
            v = Mach * a;
            mu = 1.458e-6 * T^1.5 / (T + 110.4);
            
            % Reference area
            S = obj.WingArea;
            
            %% 1. WING DRAG (from XFOIL at M=0.85)
            cd_airfoil_M085 = 0.0049;  % From XFOIL RAE2882, M=0.85
            CD0_wing = cd_airfoil_M085;  % 2D airfoil value directly
            
            %% 2. FUSELAGE DRAG
            d_fus = 6.5;   % diameter [m]
            l_fus = 76.3;  % length [m]
            fineness_ratio = l_fus/d_fus;
            
            % Reynolds number
            Re_fus = rho * v * l_fus / mu;
            
            % Skin friction (Schlichting formula)
            Cf_fus = 0.455 / (log10(Re_fus))^2.58;
            
            % Form factor
            FF_fus = 1 + 60/(fineness_ratio^3) + fineness_ratio/400;
            
            % Wetted area
            S_wet_fus = pi * d_fus * l_fus;
            
            % Fuselage CD0
            CD0_fus = Cf_fus * FF_fus * (S_wet_fus/S);
            
            %% 3. HORIZONTAL TAIL DRAG
            V_HT = 0.9;
            MAC = sqrt(S/obj.AR());
            l_HT = 38.0;
            
            S_HT = V_HT * S * MAC / l_HT;
            
            AR_HT = 5.0;
            c_HT = sqrt(S_HT / AR_HT);
            Re_HT = rho * v * c_HT / mu;
            Cf_HT = 0.455 / (log10(Re_HT))^2.58;
            FF_HT = 1.28;
            S_wet_HT = 2.1 * S_HT;
            
            CD0_HT = Cf_HT * FF_HT * (S_wet_HT / S);
            
            %% 4. VERTICAL TAIL DRAG
            V_VT = 0.07;
            l_VT = 35.0;
            
            S_VT = V_VT * S * obj.Span / l_VT;
            
            AR_VT = 1.5;
            c_VT = sqrt(S_VT / AR_VT);
            Re_VT = rho * v * c_VT / mu;
            Cf_VT = 0.455 / (log10(Re_VT))^2.58;
            FF_VT = 1.30;
            S_wet_VT = 2.1 * S_VT;
            
            CD0_VT = Cf_VT * FF_VT * (S_wet_VT / S);
            
            CD0_empennage = CD0_HT + CD0_VT;
            
            %% 5. NACELLES AND MISC
            CD0_nacelles = 0.0030;
            CD0_misc = 0.0020;
            
            %% TOTAL CD0
            CD0_total = CD0_wing + CD0_fus + CD0_empennage + ...
                        CD0_nacelles + CD0_misc;
            
            % Update object property if called without arguments (default cruise)
            if nargin < 2
                obj.CD0 = CD0_total;
            end
            
            breakdown = struct(...
                'wing', CD0_wing, ...
                'fuselage', CD0_fus, ...
                'HT', CD0_HT, ...
                'VT', CD0_VT, ...
                'empennage', CD0_empennage, ...
                'nacelles', CD0_nacelles, ...
                'misc', CD0_misc, ...
                'total', CD0_total);
        end
    end
end
