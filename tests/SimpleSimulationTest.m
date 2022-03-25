%% Simple Simulation Test
Pplenum = 550*6894.76; % high enough to be initially choked
Tplenum = 298; % room temp
Vplenum = 3.95E-3; 
Pambient = 12.7*6894.76; % atmospheric pressure
Tambient = 298; % ambient temp

A = 1.8E-6; % 1 mm^2
Cd = 1.0; 

tau = Vplenum/Cd/A/sqrt(1.4*8.3144/0.02802*Tplenum)*(2.4/2)^(2.4/0.8);
Panalytical = @(t) Pplenum*(1+.2*t/tau).^(-2.8/.4);
Tanalytical = @(t) Tplenum*(1+0.2*t/tau).^(-2);

sim = Simulation();
plenum = GasPlenum(IdealNitrogen(Pplenum,Tplenum),Vplenum);
ambient = InfiniteVolume(IdealNitrogen(Pambient,Tambient));
orifice = Orifice(Cd,A);


plenum.attach_outlet_to(orifice);
ambient.attach_inlet_to(orifice);

tend = 2*tau/.4*((Pplenum/Pambient)^(.4/2.8)*sqrt(2/2.4)-1);
tspan = [0 tend];
sim.run(tspan);
Pout = Panalytical(sim.time);
Tout = Tanalytical(sim.time);


figure(1); hold on;
title("GasPlenum Choked Blowdown");
legend;
xlabel("Simulation Time, s");
yyaxis left;
plot(sim.time,plenum.record.P,'DisplayName','Pressure (sim)');
plot(sim.time,Pout,'^','DisplayName','Pressure (analytical)');
ylabel("Pressure, Pa");
yyaxis right;
plot(sim.time,plenum.record.T,'DisplayName','Temp (sim)');
plot(sim.time,Tout,'^','DisplayName','Temp (analytical)');

ylabel("Temp, K");
