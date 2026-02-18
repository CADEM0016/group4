function [GeomObj,massObj] = wing(obj)

% ---------------- WING PLANFORM PARAMETERS ----------------
M_c_fixed = 0.85;
if isprop(obj.TLAR,'M_c'), M_c_fixed = obj.TLAR.M_c; end
if isstruct(obj.TLAR) && isfield(obj.TLAR,'M_c'), M_c_fixed = obj.TLAR.M_c; end

SweepQtrChord = real(acosd(0.75.*obj.Mstar./M_c_fixed));
tr = -0.0083*SweepQtrChord + 0.4597;

b = obj.Span;

% Use existing WingArea if set, otherwise calculate from loading (kg/m^2)
if isprop(obj, 'WingArea') && ~isempty(obj.WingArea) && obj.WingArea > 1.0
    S = obj.WingArea;
else
    % Fallback: obj.WingLoading is traditionally in kg/m^2
    loading_kg_m2 = 880; % 747-8F default
    if isprop(obj, 'WingLoading') && ~isempty(obj.WingLoading) && obj.WingLoading > 10.0
        loading_kg_m2 = obj.WingLoading;
    end
    S = obj.MTOM / loading_kg_m2;
end
obj.WingArea = S;

b = max(obj.Span, 1.0); % Ensure non-zero span

R_f = max(obj.CabinRadius, 0.1);
KinkPos = max(obj.KinkPos, R_f + 0.5);
L2 = KinkPos - R_f;
L3 = b/2 - KinkPos;

% Initial chord estimate
c_r_star  = (S/b)/(1 + tr);
c = (1-(1-tr)*KinkPos/(b/2))*c_r_star;

% Solve for correct area
c = fminsearch(@(x)(get_areas(x,L2,L3,R_f,tr,SweepQtrChord)-S).^2,c);
[~,c_t,c_r,A1,A2,A3] = get_areas(c,L2,L3,R_f,tr,SweepQtrChord);

% Use strictly unique and monotonic y-coordinates
ys = [-b/2, -KinkPos, -R_f, 0, R_f, KinkPos, b/2]';
[ys, uid] = unique(ys, 'stable');
cs = [c_t, c, c_r, c_r, c_r, c, c_t]';
cs = cs(uid);

sweepLE = atand((tand(SweepQtrChord)*L3+c/4-c_t/4)/L3);
sweepHalf = atand((tand(SweepQtrChord)*L3-c/4+c_t/4)/L3);

x_le = [tand(sweepLE)*(L2+L3) tand(sweepLE)*L2 0 0 0 tand(sweepLE)*L2 tand(sweepLE)*(L2+L3)]';
x_le = x_le(uid);
x_le = -c_r.*0.25 + x_le;
x_qtr = x_le + cs*0.25;
x_te = cs + x_le;

Xs = [x_le,ys;flipud(x_te),flipud(ys)];

% ---------------- AERODYNAMIC CENTRE ----------------

As = [A3,A2,A1,A1,A2,A3];
As_sum = [0,cumsum(As)];

idx = find(As_sum>=S/4,1,'first')-1;
if isempty(idx) || idx < 1, idx = 1; end

% Local segment properties for fminsearch
y_seg = ys(idx:idx+1);
c_seg = cs(idx:idx+1);

% Ensure segment points are unique for interp1
if y_seg(1) == y_seg(2), y_seg(2) = y_seg(1) + 1e-6; end

y_ac = fminsearch(@(y)(trapz([y_seg(1),y],interp1(y_seg,c_seg,[y_seg(1),y]))-(S/4-As_sum(idx))).^2,mean(y_seg));

obj.c_ac = interp1(ys,cs,y_ac);
obj.x_ac = interp1(ys,x_qtr,y_ac);

Xs(:,1) = Xs(:,1) + (obj.WingPos-obj.x_ac);
obj.x_ac = obj.WingPos;

GeomObj = cast.GeomObj(Name="Wing", Xs=Xs);

% ---------------- WING MASS ----------------

b_w  = obj.Span * SI.ft;
S_w  = obj.WingArea * (SI.ft)^2;

% FIX 2: realistic thickness ratio
t_w = 0.12*c_r*SI.ft;

cosLambda = cosd(sweepHalf);

% FIX 3: correct design weight for Raymer
Wdg_lb = obj.MTOM * 0.85 * SI.lb;

n_z = 2.5 * 1.5;

w_wing = 0.00125 * Wdg_lb * (b_w/cosLambda)^0.75 * ...
    (1 + sqrt(6.3*cosLambda/b_w))*n_z^0.55 * ...
    (b_w*S_w/(t_w*Wdg_lb*cosLambda))^0.3;

m_wing = w_wing / SI.lb;

massObj = cast.MassObj(Name="Wing",m=m_wing,X=[obj.x_ac;0]);

end


function [S,c_t,c_r,A1,A2,A3] = get_areas(c,L2,L3,R_f,tr,SweepQtrChord)

c_t = tr*c;

sweepLE = atand((tand(SweepQtrChord)*L3+c/4-c_t/4)/L3);
c_r = c + tand(sweepLE)*L2;

A1 = c_r*R_f;
A2 = (c_r+c)/2*L2;
A3 = (c+c_t)/2*L3;

S = 2*(A1+A2+A3);

end
