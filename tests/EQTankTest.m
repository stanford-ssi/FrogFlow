% Equlibrium Tank Test
P_initial = 4.999E6; %600*6894.76; % Pa, initial pressure
Cd = 1.0;
A = 15*0.95*1E-6; % m^2, injector area
Vtank = 6.5*1E-3; % m^3, tank volume
Atank = 0.25*pi*(4.75*0.0254)^2;
m_initial = 3.2; % initial ox mass, kg
Pamb = 14.7*6894.76; % Pa, ambient pressure
Tamb = 292.5; % K, ambient temp

% Create sim and fluid objects, updating to desired initial condition
sim = Simulation();
refull = REFPROPNitrousGas();
refliq = REFPROPNitrousLiquid();
vdwull = VDWNitrousGas();
vdwliq = VDWNitrousLiquid();
refull.update_P(P_initial);
refliq.update_P(P_initial);
vdwull.update_P(P_initial);
vdwliq.update_P(P_initial);

% Calc necessarily volumetric fill to achieve desired mass
refx = ((Vtank/m_initial)-1/refliq.rho)/(1/refull.rho-1/refliq.rho);
ref_initial_Vliq = (1-refx)*m_initial/refliq.rho;
vdwx = ((Vtank/m_initial)-1/vdwliq.rho)/(1/vdwull.rho-1/vdwliq.rho);
vdw_initial_Vliq = (1-vdwx)*m_initial/vdwliq.rho;

% Create nodes
reftank = EQTank(refull,refliq,Vtank,ref_initial_Vliq,Atank);
vdwtank = EQTank(vdwull,vdwliq,Vtank,vdw_initial_Vliq,Atank);
reforf = Orifice(Cd,A); 
vdworf = Orifice(Cd,A); 
amb = InfiniteVolume(IdealNitrogen(Pamb,Tamb),Pamb,Tamb);

% Attach nodes
reftank.attach_outlet_to(reforf);
amb.attach_inlet_to(reforf);
vdwtank.attach_outlet_to(vdworf);
amb.attach_inlet_to(vdworf);

sim.run([0 4])

%% Plotting

tanks = {reftank, vdwtank};
labs = {'REFPROP', 'VDW'};
lts = {'-','--'};
mks = {'+','.'};

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

