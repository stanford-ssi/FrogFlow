% Equlibrium Tank Test
close all; clearvars;
res_names = ["Z & K","Van Pelt","Prince (Ground)","Prince (Flight)","Zimmerman (Low $\dot{m}$)","Zimmerman (High $\dot{m}$)"];
tank_dias = [.1905,.09525,0.1207,0.1207,0.0254,0.0254];
tank_vols = [35.4E-3, 11.28E-3, 9.29E-3, 9.29E-3, 0.180E-3, 0.180E-3];
fill_levs = [0.64, 0.90, 0.95, 0.85, 0.87, 0.87];
Pi = 1E6*[4.502, 4.999, 4.777, 5.452, 4.091, 3.763];
eq_cda = 1E-6*[86.6, 19.7, 28.0, 25.5, 0.155, 0.687];
end_times = [4.91, 8.74, 5.56, 4.85, 19.88, 4.86];
resi = 5;

P_initial = Pi(resi); %600*6894.76; % Pa, initial pressure
Cd = 1.0;
A = eq_cda(resi); % m^2, injector area
Vtank = tank_vols(resi); % m^3, tank volume
Atank = 0.25*pi*(tank_dias(resi))^2;
initial_fill_frac = fill_levs(resi);
Pamb = 14.7*6894.76; % Pa, ambient pressure
Tamb = 293; % K, ambient temp

% Create sim and fluid objects, updating to desired initial condition
sim = Simulation();
refull = REFPROPNitrousGas();
refliq = REFPROPNitrousLiquid();
% vdwull = VDWNitrousGas();
% vdwliq = VDWNitrousLiquid();
refull.update_P(P_initial);
refliq.update_P(P_initial);
% vdwull.update_P(P_initial);
% vdwliq.update_P(P_initial);

% Calc necessarily volumetric fill to achieve desired mass
% refx = ((Vtank/m_initial)-1/refliq.rho)/(1/refull.rho-1/refliq.rho);
% ref_initial_Vliq = (1-refx)*m_initial/refliq.rho;
% vdwx = ((Vtank/m_initial)-1/vdwliq.rho)/(1/vdwull.rho-1/vdwliq.rho);
% vdw_initial_Vliq = (1-vdwx)*m_initial/vdwliq.rho;

% Create nodes
reftank = EQTank(refull,refliq,Vtank,initial_fill_frac*Vtank,Atank);
% vdwtank = EQTank(vdwull,vdwliq,Vtank,vdw_initial_Vliq,Atank);
reforf = TwoPhaseOrifice(Cd,A,'Dyer',refull,refliq); 
% vdworf = Orifice(Cd,A); 
amb = InfiniteVolume(IdealNitrogen(Pamb,Tamb),Pamb,Tamb);

% Attach nodes
reftank.attach_outlet_to(reforf);
amb.attach_inlet_to(reforf);
% vdwtank.attach_outlet_to(vdworf);
% amb.attach_inlet_to(vdworf);

sim.run([0 30])

%% Plotting

% tanks = {reftank, vdwtank};
% labs = {'REFPROP', 'VDW'};
% lts = {'-','--'};
% mks = {'+','.'};
tanks = {reftank};
labs = {'REFPROP'};
lts = {'-'};
mks = {'+'};

f1 = figure('Name','EQTank PT');
subplot(1,2,1); pbaspect([1 1 1]); 
title("\textbf{Tank Pressures}","Interpreter","latex");
xlabel("\textbf{Simulation Time,} s","Interpreter","latex");
ylabel("\textbf{Pressure,} Pa","Interpreter","latex");
legend("Interpreter","latex"); 
subplot(1,2,2); pbaspect([1 1 1]);
title("\textbf{Tank Temperatures}","Interpreter","latex");
xlabel("\textbf{Simulation Time,} s","Interpreter","latex");
ylabel("\textbf{Temperature,} K","Interpreter","latex");
legend("Interpreter","latex"); 

f2 = figure('Name','EQTank Mass');
title("\textbf{Tank Temperatures}","Interpreter","latex");
xlabel("\textbf{Simulation Time,} s","Interpreter","latex");
ylabel("\textbf{Mass,} kg","Interpreter","latex");
legend('Interpreter','latex');
pbaspect([1 1 1]);

f3 = figure('Name','EQTank Fill');
title("\textbf{Tank Fill Level}",'Interpreter','latex');
xlabel("\textbf{Simulation Time,} s",'Interpreter','latex');
legend('Interpreter','latex');
ylabel('\textbf{Fill Level,} \% of tank height','Interpreter','latex');
pbaspect([1 1 1]);

for plot_ind = 1:numel(tanks)
    tank = tanks{plot_ind};
    lab = labs{plot_ind};
    runout_ind = tank.liquid_node.record.m > 0;
    lt = lts{plot_ind};
    mk = mks{plot_ind};

    figure(f1); hold on;
    subplot(1,2,1); hold on;
    plot(sim.time,[tank.liquid_node.record.P(runout_ind);tank.ullage_node.record.P(~runout_ind)],lt,'Color','k','DisplayName',[lab ' Pressure']);

    subplot(1,2,2); hold on;
    plot(sim.time,tank.ullage_node.record.T,lt,'Color','k','DisplayName',[lab ' Ullage Temp']);
    plot(sim.time(runout_ind),tank.liquid_node.record.T(runout_ind),[lt mk],'Color','k','DisplayName',[lab ' Liquid Temp']);
    
    figure(f2); hold on;
    title("\textbf{Tank Blowdown Mass}","Interpreter","latex");

    plot(sim.time,tank.ullage_node.record.m,[lt mk],'Color','k','MarkerSize',4,'DisplayName',[lab ' Ullage Mass']);
%     plot(sim.time,tank.liquid_node.record.m,[lt '+'],'Color','k','DisplayName',[lab ' Liquid Mass']);
    plot(sim.time,tank.record.m,lt,'Color','k','DisplayName',[lab ' Total Mass']);
    pbaspect([1 1 1]);
    
    figure(f3); hold on;
    plot(sim.time,tank.record.fill_pct,lt,'Color','k','DisplayName',[lab ' Fill Pct']);
end
err = 100*abs(sim.time(end)-end_times(resi))/end_times(resi);
fprintf("Sim ended at %0.2f sec, compared to research result %0.2f sec (err %.2f %%) \n", sim.time(end),end_times(resi),err);
