%% MassStab.Run  — Entry point for Mass & Stability discipline
%  CADEM0016 | GDP Group 3 | University of Bristol 2025/26
%  Usage:  MassStab.Run()          % standalone with defaults
%          MassStab.Run(ADP)       % pass existing ADP object

function [massObj, cgOut, stabOut] = Run(ADP)

if nargin < 1, ADP = MassStab.ADP(); end

fprintf('\n=== Mass & Stability Module | Group 3 ===\n');

% 1. Compute mass estimates
[CI, CII, CIII] = MassStab.mass.Estimate(ADP);

% 2. Build mass object array (cast.MassObj compatible)
massObj = MassStab.mass.BuildMassObj(ADP, CIII);

% 3. CG envelope
cgOut = MassStab.stability.CG(ADP, massObj);

% 4. Static margin & neutral point
stabOut = MassStab.stability.StaticMargin(ADP, cgOut);

% 5. OEI check
MassStab.stability.OEI(ADP);

% 6. Sensitivity studies + plots
MassStab.sensitivity.Run(ADP, CI, CII, CIII, cgOut, stabOut);

fprintf('\n=== Done ===\n');
end
