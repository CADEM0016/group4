
%  DOC_Standalone.m
clear; clc; close all;

fprintf('=========================================================\n');
fprintf('  CADEM0016 - DOC Analysis - Group 4\n');
fprintf('  Modified B747-8F | 5 Aircraft | F1 2026 Season\n');
fprintf('=========================================================\n\n');

%  SECTION 1: CONFIRMED AIRCRAFT PARAMETERS

% Mass (all confirmed by student)
MTOM_kg      = 530000;    % [kg]
MTOM_t       = 530;       % [t]
OEM_kg       = 200000;    % [kg]
payload_kg   = 150000;    % [kg] per aircraft
max_fuel_kg  = 180000;    % [kg] - OEM+payload+fuel = 530t exactly

% Performance
cruise_mach  = 0.85;
cruise_alt   = 40000;     % [ft]
a_40kft      = 295.07;    % [m/s] speed of sound at 40,000ft ISA
V_ms         = cruise_mach * a_40kft;  % 250.8 m/s = 487.5 kts
LD           = 19.0;      % lift-to-drag ratio at cruise
TSFC         = 0.041;     % [kg/(N.hr)] RR UltraFan at cruise

% Engines
N_eng        = 4;         % Rolls-Royce UltraFan
T_kN         = 400;       % [kN] per engine

% Geometry
b_m          = 71;        % [m] wingspan - ICAO F
L_fus        = 76.3;      % [m] fuselage length

% Fleet
fleet        = 5;

% Economics (spec Section 4)
fuel_den     = 0.8;       % [kg/L] spec 3.6
fuel_pr_kero = 1.00;      % [$/L] Jet-A1 spec 4.4
fuel_pr_SAF  = 2.00;      % [$/L] SAF spec 4.4
park_pr      = 6000;      % [$/day] ICAO F spec 4.3

g = 9.81;

% Mass budget confirmation
fprintf('Mass Budget: %.0f + %.0f + %.0f = %.0f t (MTOM = %d t)\n', ...
    OEM_kg/1000, payload_kg/1000, max_fuel_kg/1000, ...
    (OEM_kg+payload_kg+max_fuel_kg)/1000, MTOM_t);
if OEM_kg+payload_kg+max_fuel_kg == MTOM_kg
    fprintf('Mass check: PASS - perfectly balanced\n\n');
end

%  SECTION 2: FLIGHT SCHEDULE - 17 LEGS

% Leg distances [nm] from Group 4 flight plan
dist_nm = [4350; 795; 4480; 700; 6480; 1240; 3295; 530; 2215; 3780;
           8585; 650; 4000; 5290; 7130; 160; 2970];

leg_str = {
    ' 1 MEL->PVG  Melbourne->Shanghai';
    ' 2 PVG->NGO  Shanghai->Nagoya';
    ' 3 NGO->BAH  Nagoya->Bahrain';
    ' 4 BAH->JED  Bahrain->Jeddah';
    ' 5 JED->MIA  Jeddah->Miami';
    ' 6 MIA->YUL  Miami->Montreal (EMPTY)';
    ' 7 YUL->NCE  Montreal->Nice';
    ' 8 NCE->MAD  Nice->Madrid (EMPTY)';
    ' 9 MAD->GYD  Madrid->Baku';
    '10 GYD->SIN  Baku->Singapore';
    '11 SIN->AUS  Singapore->Austin [REFUEL: HNL]';
    '12 AUS->MEX  Austin->Mexico City (EMPTY)';
    '13 MEX->GRU  Mexico City->Sao Paulo';
    '14 GRU->LAS  Sao Paulo->Las Vegas';
    '15 LAS->DOH  Las Vegas->Doha [REFUEL: LHR area]';
    '16 DOH->AUH  Doha->Abu Dhabi';
    '17 AUH->LHR  Abu Dhabi->London Heathrow (EMPTY)';
};

% Payload: 1=150t loaded, 0=empty ferry
PL = [1;1;1;1;1;0;1;0;1;1;1;0;1;1;1;1;0];

% Refuel stop flag (legs exceeding 7093.95nm design range)
RF = [0;0;0;0;0;0;0;0;0;0;1;0;0;0;1;0;0];

% Refuel sub-leg distances [nm]
% Leg 11: SIN->HNL=5095nm, HNL->AUS=3490nm (total=8585nm)
% Leg 15: LAS->LHR_area=5224nm, LHR->DOH=1906nm (total=7130nm)
sub1 = [0;0;0;0;0;0;0;0;0;0;5095;0;0;0;5224;0;0];
sub2 = [0;0;0;0;0;0;0;0;0;0;3490;0;0;0;1906;0;0];

% Totals
total_land   = 17 + sum(RF);   % 19 landings (17 legs + 2 refuel)
n_frv        = sum(PL > 0);    % 13 freight venues
park_days    = n_frv*5 + sum(RF)*(2/24);  % 65.17 days

fprintf('Season: 17 legs | %d refuel stops | %d landings\n', sum(RF), total_land);
fprintf('Freight venues: %d | Parking: %.2f days (ICAO F $%d/day)\n\n', ...
    n_frv, park_days, park_pr);

%  SECTION 3: FUEL CALCULATION PER LEG (Breguet + Spec reserves)
% Phase weight fractions
wf_tx = 0.9990; wf_to = 0.9950; wf_cl = 0.9850;
wf_de = 0.9900; wf_tg = 0.9990;

% Reserve (spec Appendix A.8)
R_alt  = 189*1852;   % alternate 350km=189nm in metres
wf_alt = exp(-R_alt*g*TSFC/(3600*V_ms*LD));
wf_lt  = 0.9940;     % 30min loiter
ctg    = 0.03;       % 3% contingency

blk_kg = zeros(17,1);
fh_leg = zeros(17,1);

fprintf('%-46s %5s %4s %8s %6s\n','Leg','nm','PL','Fuel(t)','FH');
fprintf('%s\n', repmat('-',1,73));

for i = 1:17
    OWE = OEM_kg + PL(i)*payload_kg;
    if RF(i)==1
        sd = [sub1(i), sub2(i)];
    else
        sd = dist_nm(i);
    end
    tb=0; tf=0;
    for s=1:length(sd)
        dm  = sd(s)*1852;
        wfc = exp(-dm*g*TSFC/(3600*V_ms*LD));
        wfm = wf_tx*wf_to*wf_cl*wfc*wf_de*wf_tg;
        TOW = min(MTOM_kg, OWE+max_fuel_kg);
        Wtr = TOW*(1-wfm);
        Wrs = ctg*Wtr + TOW*wfm*(1-wf_alt*wf_lt);
        Wb  = min(Wtr+Wrs, max_fuel_kg);
        thr = (dm*0.83)/(V_ms*3600) + 0.50 + 0.67 + 0.67;
        tb=tb+Wb; tf=tf+thr;
    end
    blk_kg(i) = tb;
    fh_leg(i) = tf;
    pls = '—'; if PL(i)>0; pls='150t'; end
    sfl = 'dir'; if RF(i)==1; sfl='*REF'; end
    fprintf('%-46s %5.0f %4s %8.1f %6.1f  %s\n', ...
        leg_str{i}, dist_nm(i), pls, tb/1000, tf, sfl);
end

tot_blk_kg = sum(blk_kg);
tot_fh     = sum(fh_leg);
tot_blk_L  = tot_blk_kg / fuel_den;

fprintf('%s\n', repmat('-',1,73));
fprintf('%-46s %5s %4s %8.1f %6.1f\n', ...
    'SEASON TOTAL (per aircraft)','','',tot_blk_kg/1000, tot_fh);
fprintf('\nBlock fuel = %.1f t = %s litres per aircraft per season\n\n', ...
    tot_blk_kg/1000, num2str(round(tot_blk_L)));

%  SECTION 4: CLASS I DOC (Spec Section 4 - Sprint 2)

fprintf('=========================================================\n');
fprintf('  CLASS I DOC - GDP SPEC SECTION 4\n');
fprintf('=========================================================\n\n');

% Hull value (Spec Eq.1)
Vhull = 44880 * (MTOM_kg^0.65);
fprintf('V_hull = 44,880 x %d^0.65 = $%.3fM\n\n', MTOM_kg, Vhull/1e6);

% Cost components per aircraft per year
Cc = 4 * 150000;                           % crew: spec 4.1
Cl = 25 * MTOM_t * total_land;             % landing: spec 4.2
Cp = park_pr * park_days;                  % parking: spec 4.3
Cf = tot_blk_L * fuel_pr_kero;             % fuel: spec 4.4
Cmf= 0.03  * Vhull;                        % maint fixed: spec Eq.2
Cmv= 5e-6  * Vhull * tot_fh;              % maint var: spec Eq.3
Ci = 0.005 * Vhull;                        % insurance: spec Eq.4
Cm = Cmf + Cmv;

DOC_pa = Cc+Cl+Cp+Cf+Cm+Ci;
DOC_fl = fleet * DOC_pa;

% Print table
names = {'Crew salaries (4x$150k)';'Landing fees ($25/t/ldg)';
         'Parking fees (ICAO F)';'Fuel cost (Jet-A1 $1/L)';
         'Maintenance fixed (0.03xVh)';'Maintenance var (5e-6xVhxFH)';
         'Insurance (0.005xVh)'};
vals_pa = [Cc;Cl;Cp;Cf;Cmf;Cmv;Ci];

fprintf('%-34s %13s %13s %6s\n','Component','Per Ac/yr','Fleet/yr','%');
fprintf('%s\n', repmat('-',1,70));
for r=1:7
    fprintf('  %-32s $%10.0f  $%10.0f  %4.1f%%\n', ...
        names{r}, vals_pa(r), fleet*vals_pa(r), 100*fleet*vals_pa(r)/DOC_fl);
end
fprintf('%s\n', repmat('-',1,70));
fprintf('  %-32s $%10.0f  $%10.0f  100%%\n','TOTAL DOC',DOC_pa,DOC_fl);

fprintf('\n  DOC per aircraft:   $%.4fM/yr\n', DOC_pa/1e6);
fprintf('  DOC per landing:    $%s\n', num2str(round(DOC_pa/total_land)));
fprintf('  DOC per tonne-nm:   $%.4f/t-nm\n', DOC_pa/(150*7093.95));
fprintf('  Dominant cost:      Maintenance = %.1f%% (hull value drives this)\n\n', ...
    100*fleet*Cm/DOC_fl);

%  SECTION 5: CLASS II DOC (Sprint 3 - DAPCA IV + financial overheads)

fprintf('=========================================================\n');
fprintf('  CLASS II DOC - DAPCA IV + FINANCIAL COSTS (Sprint 3)\n');
fprintf('=========================================================\n\n');

% DAPCA IV parameters (Raymer Ch.18)
Me       = OEM_kg;                 % empty mass [kg]
V_kmh    = V_ms * 3.6;            % max velocity [km/h]
N_prod   = fleet;                  % 5-year production qty = fleet size
Nft      = 2;                      % flight test aircraft
T3_K     = 1550;                   % turbine inlet temp [K] (UltraFan class)
Mmax     = 0.92;                   % design dive Mach = 0.85+0.04+0.03

% Labour hours
HE = 5.18  * Me^0.777 * V_kmh^0.894 * N_prod^0.163;
HT = 7.22  * Me^0.777 * V_kmh^0.696 * N_prod^0.263;
HM = 10.5  * Me^0.82  * V_kmh^0.484 * N_prod^0.641;
HQ = 0.076 * HM;   % cargo aircraft

% Labour rates 2012 USD
RE=115; RT=118; RM=98; RQ=108;
eta_M = 1.1;    % composite multiplier (some CFRP)

C_lab = (HE*RE + HT*RT + HM*RM + HQ*RQ) * eta_M;

% Other costs 2012 USD
C_D   = 67.4  * Me^0.63  * V_kmh^1.3;
C_F   = 1947  * Me^0.325 * V_kmh^0.822 * Nft^1.21;
C_m   = 31.2  * Me^0.921 * V_kmh^0.621 * N_prod^0.799;
C_E1  = 3112*(9.66*T_kN + 243.25*Mmax + 1.74*T3_K - 2228);
C_E   = C_E1 * N_eng;

% Total programme cost inflated to 2026
CPI   = 1.43;
C_tot = (C_lab + C_D + C_F + C_m + C_E) * CPI;
C_ac  = C_tot / N_prod;   % per aircraft purchase cost

fprintf('DAPCA IV Initial Cost Estimate:\n');
fprintf('  Labour cost         = $%.2fM (2012)\n', C_lab/1e6);
fprintf('  Development         = $%.2fM (2012)\n', C_D/1e6);
fprintf('  Flight test         = $%.2fM (2012)\n', C_F/1e6);
fprintf('  Materials           = $%.2fM (2012)\n', C_m/1e6);
fprintf('  Engines (x%d)       = $%.2fM (2012)\n', N_eng, C_E/1e6);
fprintf('  Programme total     = $%.2fM (2012) -> $%.2fM (2026, CPI=%.2f)\n', ...
    (C_lab+C_D+C_F+C_m+C_E)/1e6, C_tot/1e6, CPI);
fprintf('  Per-aircraft cost   = $%.2fM (2026)\n\n', C_ac/1e6);

% Financial overheads (lecture notes)
C_dep = C_ac / 14;          % depreciation 14-year life
C_int = 0.05 * C_ac;        % interest 5% of investment

% Class II maintenance (Raymer Eq.18.12)
Ca  = C_ac - C_E1*CPI;      % airframe cost less engines
Ce  = C_E1 * CPI;           % per engine cost 2026
maint_per_FH = (3.3*(Ca/1e6) + 14.2 + (58*(Ce/1e6) - 26.1)*N_eng) * CPI;
Cm_II_pa     = maint_per_FH * tot_fh;

% Class II Insurance (unchanged)
Ci_II_pa     = Ci;

% Class II totals
COC_II_pa = Cc + Cl + Cp + Cf + Cm_II_pa + Ci_II_pa;
DOC_II_pa = COC_II_pa + C_dep + C_int;
COC_II_fl = fleet * COC_II_pa;
DOC_II_fl = fleet * DOC_II_pa;

fprintf('Class II DOC Breakdown:\n');
fprintf('%-34s %13s %13s %6s\n','Component','Per Ac/yr','Fleet/yr','%');
fprintf('%s\n', repmat('-',1,70));
names2  = {'Crew salaries';'Landing fees';'Parking fees';'Fuel cost';
           'Maintenance (Raymer 18.12)';'Insurance';'Depreciation';'Interest'};
vals2   = [Cc;Cl;Cp;Cf;Cm_II_pa;Ci_II_pa;C_dep;C_int];
for r=1:8
    fprintf('  %-32s $%10.0f  $%10.0f  %4.1f%%\n', ...
        names2{r}, vals2(r), fleet*vals2(r), 100*fleet*vals2(r)/DOC_II_fl);
end
fprintf('%s\n', repmat('-',1,70));
fprintf('  %-32s $%10.0f  $%10.0f  100%%\n','TOTAL DOC (II)',DOC_II_pa,DOC_II_fl);
fprintf('\n  Class I vs Class II uplift: +$%.2fM/yr fleet (+%.1f%%)\n\n', ...
    (DOC_II_fl-DOC_fl)/1e6, 100*(DOC_II_fl-DOC_fl)/DOC_fl);

%  SECTION 6: SENSITIVITY 1 - Jet-A1 vs SAF

fprintf('=========================================================\n');
fprintf('  SENSITIVITY 1: Jet-A1 vs SAF\n');
fprintf('=========================================================\n\n');

DOC_SAF_fl = DOC_fl - fleet*Cf + fleet*tot_blk_L*fuel_pr_SAF;
SAF_prem   = DOC_SAF_fl - DOC_fl;

fprintf('  %-28s %14s %14s\n','','Jet-A1 ($1/L)','SAF ($2/L)');
fprintf('  %s\n', repmat('-',1,58));
fprintf('  %-28s $%12.3fM  $%12.3fM\n','Fuel cost (fleet/yr)', ...
    fleet*Cf/1e6, fleet*tot_blk_L*fuel_pr_SAF/1e6);
fprintf('  %-28s $%12.3fM  $%12.3fM\n','Total DOC (fleet/yr)', ...
    DOC_fl/1e6, DOC_SAF_fl/1e6);
fprintf('  %-28s $%12.3fM  $%12.3fM\n','DOC per aircraft/yr', ...
    DOC_fl/(fleet*1e6), DOC_SAF_fl/(fleet*1e6));
fprintf('\n  SAF premium = +$%.3fM/yr (+%.1f%% total DOC)\n\n', ...
    SAF_prem/1e6, 100*SAF_prem/DOC_fl);

%  SECTION 7: SENSITIVITY 2 - DOC vs Fleet Size

fprintf('=========================================================\n');
fprintf('  SENSITIVITY 2: DOC vs Fleet Size\n');
fprintf('  (750t total payload fixed; more aircraft = less per ac)\n');
fprintf('=========================================================\n\n');

fl_rng  = 2:1:10;
DOC_fl_v = zeros(size(fl_rng));
DOC_pa_v = zeros(size(fl_rng));
tot_fk   = fleet * tot_blk_kg;   % total fuel fixed

fprintf('  %6s %18s %18s\n','Fleet','DOC Fleet ($M/yr)','DOC/ac ($M/yr)');
fprintf('  %s\n', repmat('-',1,45));

for k=1:length(fl_rng)
    fs    = fl_rng(k);
    bL_fs = (tot_fk/fs) / fuel_den;
    D = fs*(Cc+Cl+Cp+bL_fs*fuel_pr_kero+(Cmf+Cmv)+Ci);
    DOC_fl_v(k) = D;
    DOC_pa_v(k) = D/fs;
    fl = ''; if fs==fleet; fl='  <- SELECTED'; end
    fprintf('  %6d %18.3f %18.3f%s\n',fs,D/1e6,D/(fs*1e6),fl);
end
fprintf('\n');

%  SECTION 8: SENSITIVITY 3 - DOC vs MTOM

fprintf('=========================================================\n');
fprintf('  SENSITIVITY 3: DOC vs MTOM\n');
fprintf('=========================================================\n\n');

MTOM_rng = 300:10:700;
DOC_MTOM = zeros(size(MTOM_rng));

fprintf('  %8s %12s %12s %14s\n','MTOM(t)','Vh($M)','Maint($M)','DOC Fleet($M)');
fprintf('  %s\n', repmat('-',1,50));

for k=1:length(MTOM_rng)
    mt = MTOM_rng(k); mk=mt*1000;
    vh = 44880*(mk^0.65);
    lf = fleet*25*mt*total_land;
    cm = fleet*(0.03*vh + 5e-6*vh*tot_fh);
    ci = fleet*0.005*vh;
    D  = fleet*(Cc+Cp+Cf) + lf + cm + ci;
    DOC_MTOM(k) = D;
    if mod(mt,50)==0 || mt==MTOM_t
        fl=''; if mt==MTOM_t; fl=' <-'; end
        fprintf('  %8.0f %12.2f %12.2f %14.3f%s\n', ...
            mt,vh/1e6,cm/1e6,D/1e6,fl);
    end
end
fprintf('\n');

%  SECTION 9: COMPARISON vs B777F BASELINE

fprintf('=========================================================\n');
fprintf('  COMPARISON: Group 4 vs B777F Baseline (Spec App B)\n');
fprintf('=========================================================\n\n');

Vh_777  = 44880*(348700^0.65);
fl_777  = 8; ld_777=19; pk_777=65; fh_777=tot_fh;
DOC_777 = (fl_777*600000 + fl_777*25*348.7*ld_777 + fl_777*4000*pk_777 ...
         + fl_777*(650000/fuel_den)*fuel_pr_kero ...
         + fl_777*(0.03*Vh_777+5e-6*Vh_777*fh_777) ...
         + fl_777*0.005*Vh_777);

fprintf('  %-32s %14s %14s\n','Parameter','Group3 B747-8F','B777F Baseline');
fprintf('  %s\n', repmat('-',1,62));
p = {
    'Fleet size',                sprintf('%d',fleet),      sprintf('%d',fl_777);
    'MTOM [t]',                  sprintf('%d',MTOM_t),     '348.7';
    'OEM [t]',                   sprintf('%d',OEM_kg/1e3), '145.0';
    'Max payload/ac [t]',        '150',                    '103';
    'Total payload [t]',         sprintf('%d',fleet*150),  sprintf('%d',fl_777*103);
    'Engines',                   '4x RR UltraFan',         '2x GE90-115B';
    'Design range [nm]',         '7,094',                  '~4,900';
    'Cruise altitude [ft]',      '40,000',                 '35,000';
    'Block fuel/ac [t/season]',  sprintf('%.0f',tot_blk_kg/1e3), '650';
    'Landings/ac',               sprintf('%d',total_land), sprintf('%d',ld_777);
    'Hull value [$M]',           sprintf('%.1f',Vhull/1e6),sprintf('%.1f',Vh_777/1e6);
    'TOTAL DOC fleet [$M/yr]',   sprintf('%.3f',DOC_fl/1e6),sprintf('%.3f',DOC_777/1e6);
    'DOC per aircraft [$M/yr]',  sprintf('%.3f',DOC_fl/(fleet*1e6)),sprintf('%.3f',DOC_777/(fl_777*1e6));
};
for r=1:size(p,1)
    fprintf('  %-32s %14s %14s\n',p{r,1},p{r,2},p{r,3});
end
diff_pct = 100*(DOC_fl-DOC_777)/DOC_777;
if diff_pct < 0
    fprintf('\n  Group 4 fleet is %.1f%% CHEAPER than B777F baseline\n\n', abs(diff_pct));
else
    fprintf('\n  Group 4 fleet is %.1f%% more expensive than B777F baseline\n\n', diff_pct);
end

%  SECTION 10: FIGURES

% Colourblind-safe palette (Tol bright)
CB = [0.40 0.76 0.65;   % teal
      0.99 0.55 0.38;   % orange
      0.55 0.63 0.80;   % blue-grey
      0.91 0.77 0.10;   % yellow
      0.25 0.65 0.29;   % green
      0.90 0.40 0.60;   % pink
      0.70 0.70 0.70];  % grey

% Figure 1: Pie chart DOC Class I
figure('Name','Fig 1: Class I DOC Breakdown','NumberTitle','off', ...
    'Position',[50 50 750 520]);
vals_pie = fleet * [Cc;Cl;Cp;Cf;Cmf;Cmv;Ci];
lbl_pie  = {sprintf('Crew\n(%.1f%%)',100*fleet*Cc/DOC_fl);
            sprintf('Landing\n(%.1f%%)',100*fleet*Cl/DOC_fl);
            sprintf('Parking\n(%.1f%%)',100*fleet*Cp/DOC_fl);
            sprintf('Fuel\n(%.1f%%)',100*fleet*Cf/DOC_fl);
            sprintf('Maint Fixed\n(%.1f%%)',100*fleet*Cmf/DOC_fl);
            sprintf('Maint Var\n(%.1f%%)',100*fleet*Cmv/DOC_fl);
            sprintf('Insurance\n(%.1f%%)',100*fleet*Ci/DOC_fl)};
explode = [0 0 0 0 1 0 1];
pie(vals_pie, explode, lbl_pie);
ph = findobj(gca,'Type','patch');
for k=1:min(length(ph),size(CB,1))
    ph(k).FaceColor = CB(k,:);
end
title(sprintf('Class I DOC — Fleet of %d | MTOM=%dt | Total $%.3fM/yr', ...
    fleet,MTOM_t,DOC_fl/1e6),'FontSize',12,'FontWeight','bold');

% Figure 2: Class I vs Class II comparison bar
figure('Name','Fig 2: Class I vs Class II DOC','NumberTitle','off', ...
    'Position',[820 50 700 480]);
cI_fl  = fleet * [Cc;Cl;Cp;Cf;Cm;Ci;0;0]    / 1e6;
cII_fl = fleet * [Cc;Cl;Cp;Cf;Cm_II_pa;Ci_II_pa;C_dep;C_int] / 1e6;
b = bar([cI_fl, cII_fl],'stacked');
b(1).FaceColor=[0.25 0.55 0.78]; b(2).FaceColor=[0.85 0.33 0.10];
set(gca,'XTickLabel',{'Crew','Landing','Parking','Fuel','Maint','Ins','Dep','Int'}, ...
    'FontSize',10);
ylabel('Cost [M USD/yr]','FontSize',11);
title('Class I vs Class II DOC — Fleet of 5','FontSize',12,'FontWeight','bold');
legend({'Class I','Class II additions'},'Location','northeast','FontSize',10);
grid on;

% Figure 3: Fleet size sensitivity
figure('Name','Fig 3: DOC vs Fleet Size','NumberTitle','off', ...
    'Position',[50 590 900 420]);
subplot(1,2,1);
plot(fl_rng, DOC_fl_v/1e6,'b-o','LineWidth',2,'MarkerFaceColor','b');
hold on;
plot(fleet, DOC_fl/1e6,'r*','MarkerSize',14,'LineWidth',2);
xlabel('Fleet Size','FontSize',11); ylabel('Total DOC [M$/yr]','FontSize',11);
title('Total Fleet DOC vs Fleet Size','FontSize',12);
legend({'DOC curve','Selected (n=5)'},'Location','northwest','FontSize',10);
grid on; hold off;

subplot(1,2,2);
plot(fl_rng, DOC_pa_v/1e6,'r-s','LineWidth',2,'MarkerFaceColor','r');
hold on;
plot(fleet, DOC_pa/1e6,'b*','MarkerSize',14,'LineWidth',2);
xlabel('Fleet Size','FontSize',11); ylabel('DOC per Aircraft [M$/yr]','FontSize',11);
title('Per-Aircraft DOC vs Fleet Size','FontSize',12);
legend({'DOC/ac curve','Selected (n=5)'},'Location','northeast','FontSize',10);
grid on; hold off;

% Figure 4: DOC vs MTOM
figure('Name','Fig 4: DOC vs MTOM','NumberTitle','off', ...
    'Position',[820 590 650 420]);
plot(MTOM_rng, DOC_MTOM/1e6,'k-','LineWidth',2); hold on;
plot(MTOM_t,   DOC_fl/1e6,   'ro','MarkerSize',12,'MarkerFaceColor','r');
plot(348.7,    DOC_777/1e6,  'b^','MarkerSize',12,'MarkerFaceColor','b');
xlabel('MTOM [tonnes]','FontSize',11);
ylabel('Total Fleet DOC [M$/yr]','FontSize',11);
title('Fleet DOC Sensitivity to MTOM','FontSize',12);
legend({'DOC trend', ...
        sprintf('Group 4: %dt $%.2fM',MTOM_t,DOC_fl/1e6), ...
        sprintf('B777F: 349t $%.2fM',DOC_777/1e6)}, ...
    'Location','northwest','FontSize',10);
grid on; hold off;

% Figure 5: Block fuel per leg
figure('Name','Fig 5: Block Fuel per Leg','NumberTitle','off', ...
    'Position',[50 50 1100 420]);
col_bars = repmat([0.25 0.55 0.78],17,1);
col_bars(RF==1,:) = repmat([0.85 0.25 0.25],sum(RF),1);
b5 = bar(blk_kg/1000,'FaceColor','flat','CData',col_bars);
xticks(1:17); xlabel('Leg Number','FontSize',11);
ylabel('Block Fuel [tonnes]','FontSize',11);
title('Block Fuel per Leg — Group 4 Modified B747-8F','FontSize',12);
grid on;
for i=1:17
    if RF(i)==1
        text(i, blk_kg(i)/1000+4, sprintf('%.0ft\nRefuel', blk_kg(i)/1000), ...
            'HorizontalAlignment','center','FontSize',8,'Color',[0.7 0 0]);
    end
end
lh(1)=patch(NaN,NaN,[0.25 0.55 0.78]);
lh(2)=patch(NaN,NaN,[0.85 0.25 0.25]);
legend(lh,{'Normal leg','Refuel stop leg'},'Location','northeast','FontSize',10);

%  SECTION 11: FINAL SUMMARY TABLE

fprintf('\n');
fprintf('=========================================================\n');
fprintf('  FINAL SUMMARY FOR FEDR SECTION 3.8\n');
fprintf('=========================================================\n\n');
fprintf('  AIRCRAFT:\n');
fprintf('    MTOM = %dt | OEM = %.0ft | Fuel = %.0ft | Payload = %.0ft\n', ...
    MTOM_t, OEM_kg/1e3, max_fuel_kg/1e3, payload_kg/1e3);
fprintf('    %d x RR UltraFan @ %.0fkN | Mach %.2f | %dft\n', ...
    N_eng, T_kN, cruise_mach, cruise_alt);
fprintf('\n  SEASON (per aircraft):\n');
fprintf('    Block fuel  = %.1ft  (%s litres)\n', tot_blk_kg/1e3, ...
    num2str(round(tot_blk_L)));
fprintf('    Flight hrs  = %.1f hrs\n', tot_fh);
fprintf('    Landings    = %d  (17 legs + 2 refuel stops)\n', total_land);
fprintf('    Parking     = %.1f days  (ICAO F $%d/day)\n', park_days, park_pr);
fprintf('\n  HULL VALUE: $%.3fM\n', Vhull/1e6);
fprintf('\n  %-32s %13s %13s\n','COMPONENT','Per Ac/yr','Fleet(x5)/yr');
fprintf('  %s\n', repmat('-',1,60));
allv = [Cc;Cl;Cp;Cf;Cmf;Cmv;Ci];
for r=1:7
    fprintf('  %-32s $%10.0f  $%10.0f  (%.1f%%)\n', ...
        names{r}, allv(r), fleet*allv(r), 100*fleet*allv(r)/DOC_fl);
end
fprintf('  %s\n', repmat('-',1,60));
fprintf('  %-32s $%10.0f  $%10.0f\n','TOTAL DOC (Class I)',DOC_pa,DOC_fl);
fprintf('  %-32s $%10.0f  $%10.0f\n','TOTAL DOC (Class II)',DOC_II_pa,DOC_II_fl);
fprintf('\n  SENSITIVITIES:\n');
fprintf('    SAF premium       : +$%.3fM/yr fleet (+%.1f%%)\n', ...
    SAF_prem/1e6, 100*SAF_prem/DOC_fl);
fprintf('    vs B777F baseline : $%.3fM/yr (Group 4 is %.1f%% cheaper)\n', ...
    DOC_777/1e6, abs(diff_pct));
fprintf('    Class I->Class II : +$%.3fM/yr fleet (+%.1f%%)\n', ...
    (DOC_II_fl-DOC_fl)/1e6, 100*(DOC_II_fl-DOC_fl)/DOC_fl);
fprintf('\n');
fprintf('=========================================================\n');
fprintf('  Complete. 5 figures generated.\n');
fprintf('=========================================================\n\n');
