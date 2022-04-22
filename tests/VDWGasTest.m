%% PT Testing
P = 1E6; %Pa
T = 400; %K
vdwgas = VDWNitrousGas(P,T);
R = vdwgas.R; % J/kg/K
expected_density = P/(R*T);
vdwgas.update_PT(P,T);
rel_err = relative_error(expected_density, vdwgas.density);
rel_tol = 1E-1;
assert(rel_err<rel_tol,"VDWGasTest:RelErr","Rel error :%0.5g > Rel. tolerance %0.5g",rel_err,rel_tol);

rhor_range = 0.01:.05:2.5;
Tr_range = [0.75 0.8 0.85 0.9 0.95 0.99 1 1.05];

f1 = figure('Name','VDWTest_Prho'); hold on;
ylabel('\textbf{Reduced Pressure,} $\frac{P}{P_{c}}$','Interpreter','latex'); xlabel('\textbf{Reduced Specific Volume,} $\frac{v}{v_{c}}$','Interpreter','latex');
title('\textbf{VDW Isotherms \& Vapor Curve}','Interpreter','latex');
pbaspect([1 1 1]);

f2 = figure('Name','VDWTest_PT'); hold on;
ylabel('Pressure, Pa'); xlabel('Temperature, K');
title('PT Vapor Curve');
plot(vdwgas.Tr.data*vdwgas.Tc,vdwgas.Pr.data*vdwgas.Pc);

figure(f1); hold on;
plot([1./(vdwgas.rhor.data(vdwgas.rhor.data(:,1)>rhor_range(1),1)); flip(1./(vdwgas.rhor.data(:,2)))],[vdwgas.Pr.data(vdwgas.rhor.data(:,1)>rhor_range(1)) flip(vdwgas.Pr.data)],'k','LineWidth',2,'DisplayName','Vapor Dome ');


P = zeros(length(Tr_range),length(rhor_range));
cp = zeros(length(Tr_range),length(rhor_range));
figure(f1); hold on; 
h = [];
[rho, T] = meshgrid(rhor_range, Tr_range);
for i = 1:length(Tr_range)
    for j = 1:length(rhor_range)
        vdwgas.update_rhoT(rhor_range(j)*vdwgas.rhoc,Tr_range(i)*vdwgas.Tc);
        P(i,j) = vdwgas.P/vdwgas.Pc;
        cp(i,j) = vdwgas.cp;        
    end
    [~,l] = contour([1;1;1]*(1./rhor_range),[1;1;1]*P(i,:),[0.9 0 0;0 1 0;1.1 0 0]*Tr_range(i)*ones(3,length(rhor_range)),Tr_range(i)*[1 1],'LineColor','k','ShowText','on');
    if Tr_range(i) < 1
        vdwgas.update_T(Tr_range(i)*vdwgas.Tc);
        Psat = vdwgas.P/vdwgas.Pc;
        rhor1 = interp1(vdwgas.Tr.data, vdwgas.rhor.data(:,1), Tr_range(i));
        rhor2 = interp1(vdwgas.Tr.data, vdwgas.rhor.data(:,2), Tr_range(i));
        plot(1./[rhor1 rhor2],Psat*[1 1],'--','Color',l.Color,'DisplayName','')
    end
end
set(gca,'XScale','log');
ylim([0 1.5])
legend('\textbf{Vapor Dome}','Interpreter','latex');



