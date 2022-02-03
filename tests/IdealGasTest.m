%% PT Testing
nitrogen = IdealGas(1.4, 0.02803);
P = 1e5; %Pa
T = 298.15; %K
R = nitrogen.Ru / 0.02803; % J/kg/K
expected_density = P/(R*T);
nitrogen.update_PT(P,T);
assert(relative_error(expected_density, nitrogen.density)<1E-5);

%% Cp Testing
nitrogen = IdealGas(1.4, 0.02803);
assert(relative_error(7/2*nitrogen.R, nitrogen.cp)<1E-5);

%% rhoP Testing
nitrogen = IdealGas(1.4, 0.02803);
P = 1E6;
T = 500;
R = nitrogen.Ru / 0.02803; % J/kg/K
rho = P/(R*T);
nitrogen.update_rhoP(rho,P);
assert(relative_error(T, nitrogen.temp)<1E-5);

%% rhoT Testing
nitrogen = IdealGas(1.4, 0.02803);
P = 1E6;
T = 500;
R = nitrogen.Ru / 0.02803; % J/kg/K
rho = P/(R*T);
nitrogen.update_rhoT(rho,T);
assert(relative_error(P, nitrogen.P)<1E-5);
