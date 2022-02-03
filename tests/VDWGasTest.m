%% PT Testing
nitrogen = VDWGas(5/2*VDWGas.Ru/0.02803, 0.02803, 126.2, 3.39E6);
P = 1e5; %Pa
T = 298.15; %K
R = nitrogen.Ru / 0.02803; % J/kg/K
expected_density = P/(R*T);
nitrogen.update_PT(P,T);
assert(relative_error(expected_density, nitrogen.density)<1E-5);


