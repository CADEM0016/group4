function [GeomObj,massObj] = landingGear(obj)

% Landing gear model for heavy 4-engine freighter (~530 t class)

% ------------------------------ PARAMETERS ------------------------------

% Landing mass (kg)
M_ldg = 370000;   

% Main gear height (m) – required for UltraFan clearance
L_main = 5.0;

% Nose gear height (m)
L_nose = 3.6;

% -------------------------- NOSE LANDING GEAR ---------------------------

% Raymer Eqn 15.51
m_nose = 0.125*(1.5*M_ldg)^0.566*(L_nose*SI.ft)^0.845;
m_nose = m_nose ./ SI.lb;   % kg

Xwheel = [-0.5,0.25;0.5,0.25;0.5,-0.25;-0.5,-0.25];
offset = [obj.CockpitLength,0];

GeomObj = cast.GeomObj(Name="Nose Landing Gear",Xs=Xwheel+offset);
massObj = cast.MassObj(Name="Nose Landing Gear",m=m_nose,X=offset);

% -------------------------- MAIN LANDING GEAR ---------------------------

% Total main gear mass (Raymer scaling)
m_main_total = 0.095*(1.5*M_ldg)^0.768*(L_main*SI.ft)^0.409;
m_main_total = m_main_total ./ SI.lb;

% 4 main gear units
m_each = m_main_total / 4;

% Positioning
x_main = obj.x_ac + obj.c_ac*0.4;

% Wing gear position (747-8F approx)
y_wing = obj.Span * 0.32 / 2;

% Body gear position
y_body = obj.CabinRadius*0.8;

% ---------- Wing Right ----------
offset = [x_main, y_wing];
GeomObj(end+1) = cast.GeomObj(Name="Main Wing Right",Xs=Xwheel+offset);
massObj(end+1) = cast.MassObj(Name="Main Wing Right",m=m_each,X=offset);

% ---------- Wing Left ----------
GeomObj(end+1) = cast.GeomObj(Name="Main Wing Left",Xs=Xwheel+offset.*[1 -1]);
massObj(end+1) = cast.MassObj(Name="Main Wing Left",m=m_each,X=offset.*[1 -1]);

% ---------- Body Right ----------
offset = [x_main, y_body];
GeomObj(end+1) = cast.GeomObj(Name="Main Body Right",Xs=Xwheel+offset);
massObj(end+1) = cast.MassObj(Name="Main Body Right",m=m_each,X=offset);

% ---------- Body Left ----------
GeomObj(end+1) = cast.GeomObj(Name="Main Body Left",Xs=Xwheel+offset.*[1 -1]);
massObj(end+1) = cast.MassObj(Name="Main Body Left",m=m_each,X=offset.*[1 -1]);

end
