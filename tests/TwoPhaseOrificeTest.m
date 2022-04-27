%% Two Phase Orifice Testing
clearvars; close all;

Tup = 293;
Cd = 1.0;
A = 28E-6; % m^2
figure('Name','TwoPhaseTest'); 

gases = {VDWNitrousGas(3E6,298),REFPROPNitrousGas()};
liquids = {VDWNitrousLiquid(3E6,298), REFPROPNitrousLiquid()};
names = ["VDW","REFPROP"];
for i = 1:numel(gases)
    gas = gases{i};
    liq = liquids{i};
    amb = IdealNitrogen(1E5,298);
    
    sim = Simulation();
    upstream = InfiniteVolume(liq);
    downstream = InfiniteVolume(amb);
    
    HEMorf = TwoPhaseOrifice(Cd,A,'HEM',liq,gas);
    cHEMorf = TwoPhaseOrifice(Cd,A,'ChokedHEM',liq,gas);
    SPIorf = TwoPhaseOrifice(Cd,A);
    Dyerorf = TwoPhaseOrifice(Cd,A,'Dyer',liq,gas);
    
    HEMorf.attach_inlet_to(upstream);
    HEMorf.attach_outlet_to(downstream);
    cHEMorf.attach_inlet_to(upstream);
    cHEMorf.attach_outlet_to(downstream);
    SPIorf.attach_inlet_to(upstream);
    SPIorf.attach_outlet_to(downstream);
    Dyerorf.attach_inlet_to(upstream);
    Dyerorf.attach_outlet_to(downstream);
    
    % Set upstream pressure
    liq.update_T(Tup);
    Pup = liq.P;
    
    % vary downstream pressure and collect mass flows
    Pdown = (0.01:0.01:1)*Pup;
    mdotHEM = zeros(size(Pdown));
    mdotcHEM = zeros(size(Pdown));
    mdotSPI = zeros(size(Pdown));
    mdotDyer = zeros(size(Pdown));
    
    for j = 1:length(Pdown)
        amb.update_PT(Pdown(j),298);
        [mdotHEM(j),~] = HEMorf.flowdot();
        [mdotcHEM(j),~] = cHEMorf.flowdot();
        [mdotSPI(j),~] = SPIorf.flowdot();
        [mdotDyer(j),~] = Dyerorf.flowdot();
    end
    
    
    % Plot Pdown vs mdot
    subplot(1,2,i); hold on;
    xlabel('\textbf{Normalized Downstream Pressure,} $\frac{P_2}{P_1}$','Interpreter','latex');
    ylabel('\textbf{Mass Flux,} $kg/m^2s$','Interpreter','latex');
    plot(Pdown/Pup,mdotHEM/(Cd*A),'k','DisplayName','HEM');
    plot(Pdown/Pup,mdotcHEM/(Cd*A),'k--','DisplayName','Choked HEM');
    plot(Pdown/Pup,mdotSPI/(Cd*A),'k-.','DisplayName','SPI');
    plot(Pdown/Pup,mdotDyer/(Cd*A),'k:','DisplayName','Dyer');
    title(sprintf('\\textbf{%s Fluid}',names(i)),'Interpreter','latex');
    legend('Interpreter','latex');
    pbaspect([1 1 1])
    
    % clear twophase calc
    HEMorf.flow.data = [];
    clear TwoPhaseOrifice
    clear TwoPhaseOrifice.calccritflow
end
sgtitle(sprintf('\\textbf{Two Phase Flux Models with Upstream} $T = %i^o$ K',Tup),'Interpreter','latex');

