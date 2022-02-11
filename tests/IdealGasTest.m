%% PT Testing
nitrogen = IdealGas(1.4, 0.02803);
P = 1e5; %Pa
T = 298.15; %K
R = nitrogen.Ru / 0.02803; % J/kg/K
expected_density = P/(R*T);
nitrogen.update_PT(P,T);
rel_err = relative_error(expected_density, nitrogen.density);
rel_tol = 1E-5;
assert(rel_err<rel_tol,"IdealGasTest:RelErr","Rel error :%0.5g > Rel. tolerance %0.5g",rel_err,rel_tol);

%% Cp Testing
nitrogen = IdealGas(1.4, 0.02803);
rel_err = relative_error(7/2*nitrogen.R, nitrogen.cp);
rel_tol = 1E-5;
assert(rel_err<rel_tol,"IdealGasTest:RelErr","Rel error :%0.5g > Rel. tolerance %0.5g",rel_err,rel_tol);


%% rhoP Testing
nitrogen = IdealGas(1.4, 0.02803);
P = 1E6;
T = 500;
R = nitrogen.Ru / 0.02803; % J/kg/K
rho = P/(R*T);
nitrogen.update_rhoP(rho,P);
rel_err = relative_error(T, nitrogen.temp);
rel_tol = 1E-5;
assert(rel_err<rel_tol,"IdealGasTest:RelErr","Rel error :%0.5g > Rel. tolerance %0.5g",rel_err,rel_tol);


%% rhoT Testing
nitrogen = IdealGas(1.4, 0.02803);
P = 1E6;
T = 500;
R = nitrogen.Ru / 0.02803; % J/kg/K
rho = P/(R*T);
nitrogen.update_rhoT(rho,T);
rel_err = relative_error(P, nitrogen.P);
rel_tol = 1E-5;
assert(rel_err<rel_tol,"IdealGasTest:RelErr","Rel error :%0.5g > Rel. tolerance %0.5g",rel_err,rel_tol);
