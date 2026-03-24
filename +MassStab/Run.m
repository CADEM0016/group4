% Mass & Stability discipline entry point  —  CADEM0016 GDP Group 3
% Call:  MassStab.Run()          runs with default aircraft parameters
%        MassStab.Run(ADP)       pass an existing ADP struct from the MDO
%
% Outputs
%   massObj   component mass array  (cast.MassObj compatible)
%   cg        CG envelope results
%   stab      static margin and tail volume results

function [massObj, cg, stab] = Run(ADP)

if nargin < 1
    ADP = MassStab.ADP();
end

[CI, CII, CIII] = MassStab.mass.Estimate(ADP);
massObj         = MassStab.mass.BuildMassObj(ADP, CIII);
cg              = MassStab.stability.CG(ADP, massObj);
stab            = MassStab.stability.StaticMargin(ADP, cg);
                  MassStab.stability.OEI(ADP);
                  MassStab.sensitivity.Plots(ADP, CI, CII, CIII, cg, stab);
end
