function [GeomObj,massObj] = engine(obj)
% engine - builds 4 UltraFan engines for a B747-8F configuration

%% ---------------------- Engine Definition -----------------------------

% Create UltraFan engine at cruise condition
obj.Engine = cast.eng.TurboFan.UltraFan(1, ...
    obj.TLAR.Alt_cruise, obj.TLAR.M_c);

% Scale engine to required thrust (4 engines total)
obj.Engine = obj.Engine.Rubberise(obj.Thrust/4);

%% ---------------------- Engine Geometry -------------------------------

% Basic rectangular nacelle representation
Xs = [-0.5,0.5;
       0.5,0.5;
       0.5,-0.5;
      -0.5,-0.5];

Xs = Xs .* [obj.Engine.Length, obj.Engine.Diameter];

% engine positions
y_in  = 0.30 * obj.Span/2;
y_out = 0.60 * obj.Span/2;

% Longitudinal position 
x_eng = obj.x_ac - 0.55 * obj.c_ac;

% Vertical offset from fuselage centerline
z_offset = obj.CabinRadius + 2.0 * obj.Engine.Diameter;

% Engine CG positions
offset1 = [x_eng,  y_in];    % Right inboard
offset2 = [x_eng,  y_out];   % Right outboard
offset3 = [x_eng, -y_in];    % Left inboard
offset4 = [x_eng, -y_out];   % Left outboard

% Create geometry objects
GeomObj(1) = cast.GeomObj(Name="Engine_R_In",  Xs=Xs+offset1);
GeomObj(2) = cast.GeomObj(Name="Engine_R_Out", Xs=Xs+offset2);
GeomObj(3) = cast.GeomObj(Name="Engine_L_In",  Xs=Xs+offset3);
GeomObj(4) = cast.GeomObj(Name="Engine_L_Out", Xs=Xs+offset4);

%% ---------------------- Mass Objects ----------------------------------

% Raymer installation mass estimate (Eq. 15.52)
m_install = 1.1 * (2.575 * (obj.Engine.Mass*SI.lb)^0.922) ...
            / SI.lb - obj.Engine.Mass;

% Assume pylon CG slightly forward of engine CG
offsetP1 = offset1 + [obj.Engine.Length/2, 0];
offsetP2 = offset2 + [obj.Engine.Length/2, 0];
offsetP3 = offset3 + [obj.Engine.Length/2, 0];
offsetP4 = offset4 + [obj.Engine.Length/2, 0];

% Create mass objects
massObj(1) = cast.MassObj(Name="Engine_R_In",  m=obj.Engine.Mass, X=offset1);
massObj(2) = cast.MassObj(Name="Pylon_R_In",   m=m_install,        X=offsetP1);

massObj(3) = cast.MassObj(Name="Engine_R_Out", m=obj.Engine.Mass, X=offset2);
massObj(4) = cast.MassObj(Name="Pylon_R_Out",  m=m_install,        X=offsetP2);

massObj(5) = cast.MassObj(Name="Engine_L_In",  m=obj.Engine.Mass, X=offset3);
massObj(6) = cast.MassObj(Name="Pylon_L_In",   m=m_install,        X=offsetP3);

massObj(7) = cast.MassObj(Name="Engine_L_Out", m=obj.Engine.Mass, X=offset4);
massObj(8) = cast.MassObj(Name="Pylon_L_Out",  m=m_install,        X=offsetP4);

end