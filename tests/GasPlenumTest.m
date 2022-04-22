%% GasPlenum Test
Pplenum = 4831620; %300*6894.76; % high enough to be initially choked
Tplenum =  290; % room temp
Vplenum = 8.75*1E-3; 
Pambient = 14.7*6894.76; % atmospheric pressure
Tambient = 298; % ambient temp

A = 1.8E-6; % 1 mm^2
Cd = 1.0; 

sim = Simulation();
plenum = GasPlenum(IdealNitrous(Pplenum,Tplenum),Vplenum);
vdwplenum = GasPlenum(VDWNitrousGas(Pplenum,Tplenum),Vplenum);
refnitrous = REFPROPNitrousGas();
refnitrous.update_PT(Pplenum,Tplenum);
refplenum = GasPlenum(refnitrous,Vplenum);
ambient = InfiniteVolume(IdealNitrous(Pambient,Tambient));
orifice = Orifice(Cd,A);
vdworifice = Orifice(Cd,A);
reforifice = Orifice(Cd,A);


plenum.attach_outlet_to(orifice);
ambient.attach_inlet_to(orifice);
vdwplenum.attach_outlet_to(vdworifice);
ambient.attach_inlet_to(vdworifice);
refplenum.attach_outlet_to(reforifice);
ambient.attach_inlet_to(reforifice);

f = plenum.get_fluid();
g = f.g;
R = f.R;
tau = Vplenum/Cd/A/sqrt(g*R*Tplenum)*((1+g)/2)^((1+g)/2/(g-1));
Panalytical = @(t) Pplenum*(1+(g-1)/2*t/tau).^(-2*g/(g-1));
Tanalytical = @(t) Tplenum*(1+(g-1)/2*t/tau).^(-2);

tend = 2*tau/(g-1)*((Pplenum/Pambient)^((g-1)/2/g)*sqrt(2/2/g)-1);
tspan = [0 tend];
sim.run(tspan);
Pout = Panalytical(sim.time);
Tout = Tanalytical(sim.time);


figure('Name','GasPlenumTest'); hold on;
title("GasPlenum Choked Blowdown");
legend;
xlabel("Simulation Time, s");
yyaxis left;
plot(sim.time,plenum.record.P,'DisplayName','Pressure (sim)');
plot(sim.time,vdwplenum.record.P,'--','DisplayName','VDW Pressure (sim)');
plot(sim.time,refplenum.record.P,'-.','DisplayName','REF Pressure (sim)');
plot(sim.time,Pout,'^','DisplayName','Pressure (analytical)');
ylabel("Pressure, Pa");
yyaxis right;
plot(sim.time,plenum.record.T,'DisplayName','Temp (sim)');
plot(sim.time,vdwplenum.record.T,'--','DisplayName','VDW Temp (sim)');
plot(sim.time,refplenum.record.T,'-.','DisplayName','REF Temp (sim)');
plot(sim.time,Tout,'^','DisplayName','Temp (analytical)');

ylabel("Temp, K");

figure('Name','GasPlenum h/u'); hold on;
title('GasPlenum h,u')
legend; xlabel('Simulation Time, s');
ylabel('specific energy, J/kg');
plot(sim.time,plenum.record.u,'DisplayName','Ideal Energy');
plot(sim.time,vdwplenum.record.u,'DisplayName','VDW Energy');
plot(sim.time,plenum.record.h,'DisplayName','Ideal Enthalpy');
plot(sim.time,vdwplenum.record.h,'DisplayName','VDW Enthalpy');

figure('Name','GasPlenum mdot,Udot'); hold on;
title('GasPlenum mdot')
legend;
xlabel("Simulation Time, s");
yyaxis left;
plot(sim.time,orifice.record.mdot,'DisplayName','mdot (sim)');
plot(sim.time,vdworifice.record.mdot,'--','DisplayName','VDW mdot (sim)');
ylabel("mdot, kg/s");
yyaxis right;
plot(sim.time,orifice.record.Udot,'DisplayName','Udot (sim)');
plot(sim.time,vdworifice.record.Udot,'--','DisplayName','VDW Udot (sim)');
ylabel("Udot, J/s");


