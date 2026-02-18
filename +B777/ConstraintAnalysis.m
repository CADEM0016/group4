function [ThrustToWeightRatio,WingLoading] = ConstraintAnalysis(obj)

%% estimate T/W and W/S from constraint analysis
% obj.WingLoading is in [kg/m^2] as per ADP.m defaults
% obj.ThrustToWeightRatio is dimensionless T/W0

% Calculate Area based on Wing Loading (kg/m^2)
% S = MTOM / WingLoading
obj.WingArea = obj.MTOM / obj.WingLoading;

% Calculate Thrust based on T/W and Weight
obj.Thrust = obj.ThrustToWeightRatio * obj.MTOM * 9.81;

% return values
% Note: Sizing loop might expect WingLoading in N/m^2 as return value
ThrustToWeightRatio = obj.ThrustToWeightRatio;
WingLoading = obj.WingLoading * 9.81; 
end