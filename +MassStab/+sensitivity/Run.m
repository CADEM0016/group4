%% MassStab.sensitivity.Run — Sensitivity sweeps + all 7 figures

function Run(ADP, CI, CII, CIII, cg, stab)

wg  = MassStab.geom.Wing(ADP);
L_f = ADP.CockpitLength + ADP.CabinLength + ADP.CabinRadius*1.48;
[rho_c,a_c] = MassStab.geom.Atmos(ADP.TLAR.Alt_cruise);
q_c = 0.5*rho_c*(ADP.TLAR.M_c*a_c)^2;

%% Sweep data
% 1. HTP area vs NP
S_ht_sv = linspace(70,200,60);
L_ht    = ADP.HtpPos - ADP.WingPos;
x_np_sv = 24 + stab.NP_pct - (24 + stab.NP_pct - stab.NP_pct) + ...
          arrayfun(@(s) 0.9*(stab.CLa_ht/stab.CLa_w)*(1-2*stab.CLa_w/(pi*ADP.Span^2/ADP.WingArea)) ...
          *(s/ADP.WingArea)*(L_ht/cg.MAC)*100, S_ht_sv);
% simplified recalc
AR=ADP.Span^2/ADP.WingArea; b2=1-ADP.TLAR.M_c^2;
CLa_w=stab.CLa_w; d_eps=2*CLa_w/(pi*AR);
dCM=1.3*(2*ADP.CabinRadius/ADP.Span)^2*(L_f^2*2*ADP.CabinRadius)/(ADP.WingArea*cg.MAC);
x_np_sv = arrayfun(@(s) 24-(dCM/CLa_w)*100 + 0.9*(stab.CLa_ht/CLa_w)*(1-d_eps) ...
          *(s/ADP.WingArea)*(L_ht/cg.MAC)*100, S_ht_sv);

% 2. Wing span vs wing mass
b_sv = linspace(55,90,60);
sig_al=503e6; rho_al=2780;
Ww_sv = arrayfun(@(b) ...
    (rho_al*2*(2.5*ADP.MTOM*9.81*b/8*0.85/(sig_al*0.55*0.12*wg.c_root/2)) * ...
    b/2*1.15*1.30 + 450*(1-ADP.eta_fold)*b)/1e3, b_sv);

% 3. CG fuel burn sequence
fb  = linspace(0,100,100);
W_fw = 0.667*ADP.MTOM*ADP.Mf_Fuel; W_fb = 0.333*ADP.MTOM*ADP.Mf_Fuel;
W_oew = sum([ADP.MTOM*ADP.Mf_Fuel*0 + ADP.OEM]);  % approx
x_oew = cg.OEW_m;
cg_fb = arrayfun(@(f) ...
    cg_at_burn(f/100*ADP.MTOM*ADP.Mf_Fuel, W_fw, W_fb, W_oew, x_oew, ...
    ADP.TLAR.Payload, ADP.CockpitLength+ADP.CabinLength/2, ...
    ADP.WingPos+wg.MAC*0.15, ADP.WingPos+wg.MAC*0.05, wg.x_LE_MAC, wg.MAC), fb);

% 4. MTOM vs OEW
MTOM_sv = linspace(300e3,650e3,60);
OEW_I_sv  = arrayfun(@(W) 0.0440*W^0.758*(ADP.Span^2/ADP.WingArea)^0.6 + ...
             0.328*(L_f*ADP.CabinRadius*2)^0.5*W^0.5 + 0.044*W + 0.090*W, MTOM_sv);

%% Figures
figure('Name','OEW Breakdown','Position',[50 50 1100 620]);
comp={'Wing','Fus','HTP','VTP','LG','Prop','Sys'};
dI  =[CI.W_wing,  CI.W_fus,  CI.W_ht,  CI.W_vt,  CI.W_lg,  CI.W_prop,  CI.W_sys]/1e3;
dII =[CII.W_wing, CII.W_fus, CII.W_ht, CII.W_vt, CII.W_lg, CII.W_prop, CII.W_sys]/1e3;
dIII=[CIII.W_wing,CIII.W_fus,CIII.W_ht,CIII.W_vt,CIII.W_lg,CIII.W_prop,CIII.W_sys]/1e3;
X=reordercats(categorical(comp),comp);
bh=bar(X,[dI;dII;dIII]','grouped');
bh(1).FaceColor=[.2 .4 .8]; bh(2).FaceColor=[.9 .5 .1]; bh(3).FaceColor=[.2 .7 .3];
ylabel('Mass [t]'); title('OEW Breakdown — Class I/II/II.5');
legend({'I','II','II.5'},'Location','ne'); grid on;

figure('Name','CG Envelope','Position',[100 50 900 650]);
plot_potato(ADP, cg, stab, wg);

figure('Name','SM vs HTP Area','Position',[150 50 800 500]);
plot(S_ht_sv, x_np_sv-cg.MTOM_pct,'b-','LineWidth',2); hold on;
xline(ADP.HtpArea,'r--','LineWidth',2,'Label',sprintf('%.0fm²',ADP.HtpArea));
yline(5,'g--'); yline(35,'m--');
xlabel('S_{HT} [m²]'); ylabel('SM at MTOM [%MAC]');
title('Static Margin vs HTP Area'); grid on;

figure('Name','Wing Mass vs Span','Position',[200 50 800 500]);
plot(b_sv,Ww_sv,'b-','LineWidth',2); hold on;
xline(ADP.Span,'r--','Label',sprintf('b=%.0fm',ADP.Span));
xline(ADP.b_taxi,'g--','Label',sprintf('taxi=%.0fm',ADP.b_taxi));
xlabel('Span [m]'); ylabel('Wing Mass [t]');
title('Wing Structural Mass vs Span (II.5)'); grid on;

figure('Name','OEW vs MTOM','Position',[250 50 800 500]);
plot(MTOM_sv/1e3,OEW_I_sv/1e3,'b--','LineWidth',2,'DisplayName','Class I'); hold on;
plot(MTOM_sv/1e3,MTOM_sv*0.47/1e3,'r-','LineWidth',2,'DisplayName','Class II');
plot(ADP.MTOM/1e3,CIII.OEW_total/1e3,'kp','MarkerSize',14,'MarkerFaceColor','y','DisplayName','II.5');
plot(348.7,145,'gs','MarkerSize',12,'MarkerFaceColor','g','DisplayName','B777F');
xlabel('MTOM [t]'); ylabel('OEW [t]'); title('OEW vs MTOM'); legend; grid on;

figure('Name','CG Fuel Burn','Position',[300 50 800 500]);
plot(fb,cg_fb,'b-','LineWidth',2); hold on;
xline(W_fb/(ADP.MTOM*ADP.Mf_Fuel)*100,'r--','Label','Belly empty');
yline(stab.NP_pct,'k--','Label',sprintf('NP=%.0f%%',stab.NP_pct));
yline(stab.NP_pct-5,'g--'); yline(stab.NP_pct-35,'m--');
xlabel('Fuel Burned [%]'); ylabel('CG [%MAC]');
title('CG Migration — Belly-First Strategy'); grid on;

figure('Name','Mass Fractions','Position',[350 50 1000 400]);
lbs={'Wing','Fus','HTP+VTP','LG','Prop','Sys'};
subplot(1,3,1); pie_6(CI,  lbs); title('Class I');
subplot(1,3,2); pie_6(CII, lbs); title('Class II');
subplot(1,3,3); pie_6(CIII,lbs); title('Class II.5');
sgtitle('OEW Fractions'); colormap(parula(6));

fprintf('  Sensitivity figures done.\n');
end

%% helpers
function pie_6(S,lbs)
    pie([S.W_wing,S.W_fus,S.W_ht+S.W_vt,S.W_lg,S.W_prop,S.W_sys],lbs);
end

function plot_potato(ADP, cg, stab, wg)
pct = @(x)(x-wg.x_LE_MAC)/wg.MAC*100;
x_fw=ADP.WingPos+wg.MAC*0.15; x_fb=ADP.WingPos+wg.MAC*0.05;
x_pay=ADP.CockpitLength+ADP.CabinLength/2;
W_fw=0.667*ADP.MTOM*ADP.Mf_Fuel; W_fb=0.333*ADP.MTOM*ADP.Mf_Fuel;
W0=ADP.OEM;  x0=cg.OEW_m;
% seq A: payload then fuel
wa=[W0,W0+ADP.TLAR.Payload*0.5,W0+ADP.TLAR.Payload, ...
    W0+ADP.TLAR.Payload+W_fw*0.5,W0+ADP.TLAR.Payload+W_fw, ...
    W0+ADP.TLAR.Payload+W_fw+W_fb]/1e3;
ma=[x0*W0, x0*W0+0.5*ADP.TLAR.Payload*x_pay, x0*W0+ADP.TLAR.Payload*x_pay, ...
    x0*W0+ADP.TLAR.Payload*x_pay+0.5*W_fw*x_fw, ...
    x0*W0+ADP.TLAR.Payload*x_pay+W_fw*x_fw, ...
    x0*W0+ADP.TLAR.Payload*x_pay+W_fw*x_fw+W_fb*x_fb];
cgA=pct(ma./(wa*1e3));
plot(cgA,wa,'b-o','LineWidth',2,'DisplayName','Payload\rightarrowFuel'); hold on;
xline(stab.NP_pct,'k--','LineWidth',2,'Label',sprintf('NP=%.0f%%',stab.NP_pct));
xline(stab.NP_pct-5,'g--'); xline(stab.NP_pct-35,'m--');
plot(cg.MTOM_pct,ADP.MTOM/1e3,'kp','MarkerSize',12,'MarkerFaceColor','y','DisplayName','MTOM');
plot(cg.MLW_pct, ADP.Mf_Ldg*ADP.MTOM/1e3,'k^','MarkerSize',10,'MarkerFaceColor','c','DisplayName','MLW');
xlabel('CG [%MAC]'); ylabel('Mass [t]');
title('CG Envelope (Potato Diagram)'); legend('Location','se'); grid on; xlim([10 85]);
end

function v = cg_at_burn(fb, Wfw, Wfb, Woew, Xoew, Wpay, Xpay, Xfw, Xfb, xLE, MAC)
    belly_r = max(0, Wfb - fb);
    wing_r  = max(0, Wfw - max(0, fb-Wfb));
    W = Woew + Wpay + belly_r + wing_r;
    X = Xoew*Woew + Xpay*Wpay + Xfb*belly_r + Xfw*wing_r;
    v = (X/W - xLE)/MAC*100;
end
