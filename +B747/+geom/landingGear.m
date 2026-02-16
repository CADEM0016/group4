function [GeomObj,massObj] = landingGear(obj)
% landingGear - generic landing gear model for 747-8F

% --------------------------- Create Geometry ----------------------------
% Simplified representation
radius = obj.CabinRadius;
length = obj.CabinLength;
nosePos = obj.CockpitLength;

% Main Gear (under wing/fuselage junction)
x_main = obj.WingPos + obj.c_ac*0.5;
% Nose Gear
x_nose = nosePos + 2;

% Create geometry (visual placeholders)
GeomObj = cast.GeomObj.empty;

% ------------------------- Create Mass Objects --------------------------
% Torenbeek estimation for landing gear mass
% M_lg = K_gr * (A + B*MTOM^0.75 + C*MTOM + D*MTOM^1.5)
% Simplified: 4% of MTOM is a standard initial guess for heavy transport
m_lg = 0.04 * obj.MTOM;

% Split: 15% Nose, 85% Main
m_nose = 0.15 * m_lg;
m_main = 0.85 * m_lg;

massObj = cast.MassObj.empty;
massObj(1) = cast.MassObj(Name="Nose Gear", m=m_nose, X=[x_nose, 0]);
massObj(2) = cast.MassObj(Name="Main Gear", m=m_main, X=[x_main, 0]);

end
