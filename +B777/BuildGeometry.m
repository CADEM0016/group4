function [GeomObj,massObj] = BuildGeometry(obj,opts)
arguments
    obj
    opts.FuelFraction = 1;
    opts.PayloadFraction = 1;
end

% Wing
GeomObj = struct.empty;
massObj = struct.empty;

FuncNames = ["wing","empenage","fuselage","engine","landingGear"];

for i = 1:length(FuncNames)
    [gTmp,mTmp] = B777.geom.(FuncNames(i))(obj); 
    GeomObj = [GeomObj,gTmp]; % Accumulate geom objects
    massObj = [massObj, mTmp]; % Accumulate mass objects
end

% add fuel mass
massObj(end+1) = cast.MassObj(Name="Fuel",m=obj.MTOM*obj.Mf_Fuel*opts.FuelFraction,...
                    X=[obj.WingPos+obj.c_ac*0.15,0]);
% add payload mass
m_pay = 150000; % Hardcoded for 747-8F
massObj(end+1) = cast.MassObj(Name="Payload",m=m_pay*opts.PayloadFraction,...
                    X=[obj.CockpitLength+obj.CabinLength/2,0]);

% add ballast/systems to reach target OEM (200t)
m_current_oem = sum([massObj(~contains([massObj.Name],["Fuel","Payload"])).m]);
m_ballast = max(0, 200000 - m_current_oem);
massObj(end+1) = cast.MassObj(Name="Systems_Misc", m=m_ballast, X=[obj.WingPos,0]);
end