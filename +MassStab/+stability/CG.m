% CG envelope across four flight conditions
%
% The CG position as a percentage of MAC is computed for:
%   OEW          empty aircraft, no fuel, no payload
%   MTOM         full fuel and full payload
%   Mid-cruise   belly tank empty, 40% wing fuel remaining
%   MLW          belly tank empty, 5% wing fuel reserve only
%
% The belly-first burn strategy intentionally moves CG aft during cruise
% (reducing trim drag) then forward again for landing (improving stability).

function cg = CG(ADP, massObj)

w       = MassStab.geom.Wing(ADP);
pct_MAC = @(x) (x - w.x_LE_MAC) / w.MAC * 100;

% Weighted-mean x-position over a subset of mass components
weighted_x = @(subset) sum([subset.m] .* cellfun(@(X) X(1), {subset.X})) / sum([subset.m]);

% Identify loading components (excluded from the OEW calculation)
is_loading = @(name) any(strcmp(name, {'Fuel Wing','Fuel Belly','Payload'}));
oew_parts  = massObj(~arrayfun(@(m) is_loading(m.Name), massObj));

x_OEW  = weighted_x(oew_parts);
x_MTOM = weighted_x(massObj);

% Pull individual fuel component masses and positions
W_fuel_wing  = massObj(strcmp({massObj.Name}, 'Fuel Wing')).m;
W_fuel_belly = massObj(strcmp({massObj.Name}, 'Fuel Belly')).m;
x_fuel_wing  = massObj(strcmp({massObj.Name}, 'Fuel Wing')).X(1);
x_fuel_belly = massObj(strcmp({massObj.Name}, 'Fuel Belly')).X(1);

W_MTOM     = sum([massObj.m]);
moment_MTOM = W_MTOM * x_MTOM;

% MLW: belly burned completely + wing fuel burned down to 5% reserve
W_reserve  = 0.05 * ADP.MTOM * ADP.Mf_Fuel;
W_MLW      = W_MTOM - W_fuel_belly - (W_fuel_wing - W_reserve);
x_MLW      = (moment_MTOM - W_fuel_belly*x_fuel_belly ...
              - (W_fuel_wing - W_reserve)*x_fuel_wing) / W_MLW;

% Mid-cruise: belly burned + 60% of wing fuel burned
W_mid_cruise = W_MTOM - W_fuel_belly - 0.60*W_fuel_wing;
x_mid_cruise = (moment_MTOM - W_fuel_belly*x_fuel_belly ...
                - 0.60*W_fuel_wing*x_fuel_wing) / W_mid_cruise;

cg.MAC      = w.MAC;
cg.x_LE_MAC = w.x_LE_MAC;
cg.OEW_m    = x_OEW;          cg.OEW_pct  = pct_MAC(x_OEW);
cg.MTOM_m   = x_MTOM;         cg.MTOM_pct = pct_MAC(x_MTOM);
cg.MC_m     = x_mid_cruise;   cg.MC_pct   = pct_MAC(x_mid_cruise);
cg.MLW_m    = x_MLW;          cg.MLW_pct  = pct_MAC(x_MLW);

fprintf('\nMAC = %.2f m    x_LE_MAC = %.2f m from nose\n', w.MAC, w.x_LE_MAC);
fprintf('\n%-16s  %7s  %9s\n', 'Condition', 'x [m]', 'CG [%%MAC]');
fprintf('%s\n', repmat('-',1,38));
fprintf('%-16s  %7.2f  %9.1f\n', 'OEW',        x_OEW,        cg.OEW_pct);
fprintf('%-16s  %7.2f  %9.1f\n', 'MTOM',       x_MTOM,       cg.MTOM_pct);
fprintf('%-16s  %7.2f  %9.1f\n', 'Mid-Cruise', x_mid_cruise, cg.MC_pct);
fprintf('%-16s  %7.2f  %9.1f\n', 'MLW',        x_MLW,        cg.MLW_pct);
end
