%% MassStab.stability.CG — CG estimation across flight phases
%  Arms follow BuildGeometry.m pattern exactly

function cg = CG(ADP, massObj)

wg  = MassStab.geom.Wing(ADP);
pct = @(x) (x - wg.x_LE_MAC) / wg.MAC * 100;

fuel_idx  = ismember({massObj.Name},{'Fuel_Wing','Fuel_Belly','Payload'});
oew_idx   = ~fuel_idx;
belly_idx = strcmp({massObj.Name},'Fuel_Belly');
wing_idx  = strcmp({massObj.Name},'Fuel_Wing');

W_oew  = sum([massObj(oew_idx).m]);
x_oew  = wmean(massObj(oew_idx));

W_mtom = sum([massObj.m]);
x_mtom = wmean(massObj);

% MLW: belly burned, wing fuel mostly burned (5% reserve)
W_res    = 0.05*ADP.MTOM*ADP.Mf_Fuel;
W_fw     = massObj(wing_idx).m;
x_fw_arm = massObj(wing_idx).X(1);
W_mlw    = W_mtom - massObj(belly_idx).m - (W_fw - W_res);
x_mlw    = (W_mtom*x_mtom - massObj(belly_idx).m*massObj(belly_idx).X(1) ...
            - (W_fw-W_res)*x_fw_arm) / W_mlw;

% Mid-cruise: belly empty, 40% wing fuel left
W_mc  = W_mtom - massObj(belly_idx).m - 0.60*W_fw;
x_mc  = (W_mtom*x_mtom - massObj(belly_idx).m*massObj(belly_idx).X(1) ...
         - 0.60*W_fw*x_fw_arm) / W_mc;

cg.MAC       = wg.MAC;
cg.x_LE_MAC  = wg.x_LE_MAC;
cg.OEW_m     = x_oew;  cg.OEW_pct  = pct(x_oew);
cg.MTOM_m    = x_mtom; cg.MTOM_pct = pct(x_mtom);
cg.MC_m      = x_mc;   cg.MC_pct   = pct(x_mc);
cg.MLW_m     = x_mlw;  cg.MLW_pct  = pct(x_mlw);

fprintf('\n  CG Results  (MAC=%.2fm, x_LE_MAC=%.2fm)\n', wg.MAC, wg.x_LE_MAC);
fprintf('  %-14s  x=%6.2fm  %5.1f%%MAC\n','OEW',      x_oew,  cg.OEW_pct);
fprintf('  %-14s  x=%6.2fm  %5.1f%%MAC\n','MTOM',     x_mtom, cg.MTOM_pct);
fprintf('  %-14s  x=%6.2fm  %5.1f%%MAC\n','Mid-Cruise',x_mc,  cg.MC_pct);
fprintf('  %-14s  x=%6.2fm  %5.1f%%MAC\n','MLW',      x_mlw,  cg.MLW_pct);
end

function xc = wmean(m)
    xc = sum([m.m].*cellfun(@(x)x(1),{m.X})) / sum([m.m]);
end
