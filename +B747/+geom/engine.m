function [GeomObj,massObj] = engine(obj)
% engine - this function builds the engines for a B747-8F (4 engines)
% engine is based upon a rubberised version of the GE90/GEnx

% Create engine object (approximated as GEnx-2B67)
% GEnx diameter is slightly smaller than GE90, but rubberising handles scale
obj.Engine = cast.eng.TurboFan.GE90(1,obj.TLAR.Alt_cruise,obj.TLAR.M_c);

% Rubberise engine to required thrust
% CRITICAL: 747 has 4 engines, so each provides Thrust/4
obj.Engine = obj.Engine.Rubberise(obj.Thrust/4);

% --------------------------- Create Geometry ----------------------------
Xs = [-0.5,0.5;0.5,0.5;0.5,-0.5;-0.5,-0.5];
Xs = Xs.*[obj.Engine.Length,obj.Engine.Diameter];

% Engine Positions (Spanwise)
% Estimating inboard at ~40% and outboard at ~70% of semi-span
span_semi = obj.Span / 2;
y_inboard = span_semi * 0.40;
y_outboard = span_semi * 0.70;

% Engine Offsets (Longitudinal & Vertical)
% Engines usually forward of wing LE
x_offset = obj.WingPos + obj.x_ac - obj.c_ac*0.8; 
z_offset = obj.CabinRadius - 1.5; % Below wing

% Inboard Engine Locations
offsetEng_In = [x_offset, z_offset];
% Outboard Engine Locations (slightly further back due to sweep)
offsetEng_Out = [x_offset + (y_outboard-y_inboard)*tand(30), z_offset]; 

% Create Geometry Objects
GeomObj = cast.GeomObj.empty;
% Inboard Right
GeomObj(1) = cast.GeomObj(Name="Engine Inboard Right",Xs=Xs+offsetEng_In);
% Inboard Left
GeomObj(2) = cast.GeomObj(Name="Engine Inboard Left",Xs=Xs+offsetEng_In.*[1 -1]);
% Outboard Right
GeomObj(3) = cast.GeomObj(Name="Engine Outboard Right",Xs=Xs+offsetEng_Out);
% Outboard Left
GeomObj(4) = cast.GeomObj(Name="Engine Outboard Left",Xs=Xs+offsetEng_Out.*[1 -1]);


% ------------------------- Create Mass Objects --------------------------

% engine installation mass (Raymer 15.52)
m_engi = 1.1*(2.575*(obj.Engine.Mass*SI.lb)^0.922)./SI.lb - obj.Engine.Mass;

offsetPylon_In = offsetEng_In+[obj.Engine.Length/2,0];
offsetPylon_Out = offsetEng_Out+[obj.Engine.Length/2,0];

massObj = cast.MassObj.empty;

% Inboard Right
massObj(1) = cast.MassObj(Name="Engine Inboard Right",m=obj.Engine.Mass,X=offsetEng_In);
massObj(2) = cast.MassObj(Name="Pylon Inboard Right",m=m_engi,X=offsetPylon_In);

% Inboard Left
massObj(3) = cast.MassObj(Name="Engine Inboard Left",m=obj.Engine.Mass,X=offsetEng_In.*[1 -1]);
massObj(4) = cast.MassObj(Name="Pylon Inboard Left",m=m_engi,X=offsetPylon_In.*[1 -1]);

% Outboard Right
massObj(5) = cast.MassObj(Name="Engine Outboard Right",m=obj.Engine.Mass,X=offsetEng_Out);
massObj(6) = cast.MassObj(Name="Pylon Outboard Right",m=m_engi,X=offsetPylon_Out);

% Outboard Left
massObj(7) = cast.MassObj(Name="Engine Outboard Left",m=obj.Engine.Mass,X=offsetEng_Out.*[1 -1]);
massObj(8) = cast.MassObj(Name="Pylon Outboard Left",m=m_engi,X=offsetPylon_Out.*[1 -1]);

end
