%% MassStab.geom.Wing — Wing planform geometry
%  Mirrors +B747/+geom/wing.m  get_areas logic exactly
%  Returns: sweep angles, chords, MAC, derived geometry

function geom = Wing(ADP)

M_c   = ADP.TLAR.M_c;
SweepQtrChord = real(acosd(0.75 * ADP.Mstar / M_c));
tr    = -0.0083 * SweepQtrChord + 0.4597;

R_f = ADP.CabinRadius;
L2  = ADP.KinkPos - R_f;
L3  = ADP.Span/2  - ADP.KinkPos;

% Solve kink chord for correct area  (wing.m pattern)
c0 = (ADP.WingArea/ADP.Span)/(1+tr) * (1-(1-tr)*ADP.KinkPos/(ADP.Span/2));
c  = fminsearch(@(x)(get_areas(x,L2,L3,R_f,tr,SweepQtrChord)-ADP.WingArea).^2, c0);
[~,c_t,c_r] = get_areas(c,L2,L3,R_f,tr,SweepQtrChord);

sweepLE   = atand((tand(SweepQtrChord)*L3 + c/4 - c_t/4)/L3);
sweepHalf = atand((tand(SweepQtrChord)*L3 - c/4 + c_t/4)/L3);

% MAC  (standard formula)
MAC = (2/3)*c_r*(1+tr+tr^2)/(1+tr);

geom.SweepQtrChord = SweepQtrChord;
geom.sweepLE       = sweepLE;
geom.sweepHalf     = sweepHalf;
geom.taper         = tr;
geom.c_root        = c_r;
geom.c_tip         = c_t;
geom.c_kink        = c;
geom.MAC           = MAC;
geom.x_LE_MAC      = ADP.WingPos - 0.25*MAC;
end

function [S,c_t,c_r,A1,A2,A3] = get_areas(c,L2,L3,R_f,tr,SweepQtrChord)
    c_t = tr*c;
    sweepLE = atand((tand(SweepQtrChord)*L3+c/4-c_t/4)/L3);
    c_r = c + tand(sweepLE)*L2;
    A1=c_r*R_f; A2=(c_r+c)/2*L2; A3=(c+c_t)/2*L3;
    S=2*(A1+A2+A3);
end
