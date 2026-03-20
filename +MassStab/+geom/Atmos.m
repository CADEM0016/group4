%% MassStab.geom.Atmos — ISA atmosphere (standalone cast.atmos replacement)
function [rho, a] = Atmos(h)
    if h <= 11000
        T = 288.15 - 0.0065*h;
        p = 101325*(T/288.15)^5.2561;
    else
        T = 216.65;
        p = 22632*exp(-9.80665*(h-11000)/(287.05*T));
    end
    rho = p/(287.05*T);
    a   = sqrt(1.4*287.05*T);
end
