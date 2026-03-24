% ISA standard atmosphere  replaces cast.atmos() for standalone use
% Inputs:   h_m   altitude above sea level [m]
% Outputs:  rho   air density              [kg/m³]
%           a     speed of sound           [m/s]

function [rho, a] = Atmos(h_m)

R_air    = 287.05;   % specific gas constant for dry air  [J/kg/K]
gamma    = 1.4;      % ratio of specific heats

% Troposphere (0 – 11 000 m): temperature falls at 6.5 K/km
if h_m <= 11000
    T = 288.15 - 0.0065 * h_m;
    p = 101325 * (T / 288.15)^5.2561;

% Stratosphere (above 11 000 m): isothermal at 216.65 K
else
    T = 216.65;
    p = 22632 * exp(-9.80665 * (h_m - 11000) / (R_air * T));
end

rho = p / (R_air * T);
a   = sqrt(gamma * R_air * T);
end
