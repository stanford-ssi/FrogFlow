%% Tank Test
Ptank = 550*6894.76; % high enough to be initially choked
Ttank = 298; % room temp
Vtank = 3.95E-3; 
Vliq = 1.9E-3;
Dtank = 5*0.0254; % diameter
Pambient = 12.7*6894.76; % atmospheric pressure
Tambient = 298; % ambient temp

A = 1.8E-6; % 1 mm^2 = 1E-6 m^2
Cd = 1.0; 

sim = Simulation();
tank = SPITank(IdealNitrogen(Ptank,Ttank),Water(Ptank,Ttank),Vtank,Vliq,pi/4*(Dtank^2));
ambient = InfiniteVolume(IdealNitrogen(Pambient,Tambient));
orifice = Orifice(Cd,A);

tank.attach_outlet_to(orifice,0);
ambient.attach_inlet_to(orifice);
tank.detach_outlets();
ambient.detach_inlets();
tank.attach_outlet_to(orifice,0);
ambient.attach_inlet_to(orifice);

tspan = [0 20];
sim.run(tspan);

figure('Name','SPITank PT'); hold on;
title("Tank Blowdown");
xlabel("Simulation Time, s");
legend;
yyaxis left;
plot(sim.time,tank.ullage_node.record.P,'DisplayName','Ullage Pressure');
plot(sim.time,tank.liquid_node.record.P,'-o','DisplayName','Liquid Pressure');
ylabel("Pressure, Pa");
yyaxis right;
plot(sim.time,tank.ullage_node.record.T,'DisplayName','Ullage Temp');
plot(sim.time,tank.liquid_node.record.T,'-o','DisplayName','Liquid Temp');
ylabel("Temp, K");

figure('Name','SPITank Fill'); hold on;
title("Tank");
xlabel("Simulation Time, s");
legend;
yyaxis left;
plot(sim.time,tank.record.zliq,'DisplayName','Liquid Height');
ylabel("Liquid Height, m");
yyaxis right;
plot(sim.time,tank.record.fill_pct,'DisplayName','Fill Pct');
ylabel("/% Full of Liquid");

sim.run([0 20]);

figure('Name','SPITank PT'); hold on;
title("Tank Blowdown");
xlabel("Simulation Time, s");
legend;
yyaxis left;
plot(sim.time,tank.ullage_node.record.P,'DisplayName','Ullage Pressure');
plot(sim.time,tank.liquid_node.record.P,'-o','DisplayName','Liquid Pressure');
ylabel("Pressure, Pa");
yyaxis right;
plot(sim.time,tank.ullage_node.record.T,'DisplayName','Ullage Temp');
plot(sim.time,tank.liquid_node.record.T,'-o','DisplayName','Liquid Temp');
ylabel("Temp, K");

figure('Name','SPITank Fill'); hold on;
title("Tank");
xlabel("Simulation Time, s");
legend;
yyaxis left;
plot(sim.time,tank.record.zliq,'DisplayName','Liquid Height');
ylabel("Liquid Height, m");
yyaxis right;
plot(sim.time,tank.record.fill_pct,'DisplayName','Fill Pct');
ylabel("/% Full of Liquid");