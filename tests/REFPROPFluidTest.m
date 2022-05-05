%% REFPROP Fluid Test
plotsurf = true;
refgas = REFPROPNitrousGas();
refliq = REFPROPNitrousLiquid();

vdwgas = VDWNitrousGas();

% Compare saturation curves
n = 100;
Tsatrange = linspace(refgas.Tmin, refgas.Tmax, n);

refrhog = ones(n,1);
refrhol = ones(n,1);
refPsat = ones(n,1);
for i = 1:n
    refgas.update_T(Tsatrange(i));
    refPsat(i) = refgas.P;
    refrhog(i) = refgas.rho;
    refliq.update_T(Tsatrange(i));
    refrhol(i) = refliq.rho;
end

vdwrhog = vdwgas.rhor.data(:,1)*vdwgas.rhoc;
vdwrhol = vdwgas.rhor.data(:,2)*vdwgas.rhoc;
vdwPsat = (vdwgas.Pr.data.')*vdwgas.Pc;
vdwTsat = (vdwgas.Tr.data.')*vdwgas.Tc;

% Property surface calcs
nt = 100;
nr = 100;
logbase = 100;
Trange = refgas.Tmax*log10(linspace(logbase^(240/vdwgas.Tmax),logbase^(309/vdwgas.Tmax),nt))/log10(logbase); 
rhorange = vdwgas.rhoc*logspace(log10(3E-3),log10(5),nr);%vdwgas.rhoc*linspace(3E-3,5,nr);
[Trange, rhorange] = meshgrid(Trange,rhorange);
vdwP = zeros(size(Trange));
refP = zeros(size(Trange));
refPl = zeros(size(Trange));
for i = 1:nr
    for j = 1:nt
        refgas.update_rhoT(rhorange(i,j),Trange(i,j));
        refliq.update_rhoT(rhorange(i,j),Trange(i,j));
        vdwgas.update_rhoT(rhorange(i,j),Trange(i,j));
        refP(i,j) = refgas.P;
        refPl(i,j) = refliq.P;
        vdwP(i,j) = vdwgas.P;
    end
end

%% Plotting
% close all;
figure('Name','REFPROP_Pv'); hold on;
title('\textbf{Comparison of Vapor Curves \& Isotherms}','interpreter','latex');
refh = plot(1./[refrhog; flip(refrhol)], [refPsat; flip(refPsat)],'k','DisplayName','REFPROP Vapor Dome','LineWidth',2);
vdwh = plot(1./[vdwrhog; flip(vdwrhol)], [vdwPsat; flip(vdwPsat)],'b','DisplayName','VDW Vapor Dome','LineWidth',2); 
xlabel('\textbf{Specific volume,} $\frac{m^3}{kg}$','interpreter','latex');
ylabel('\textbf{Pressure,} Pa','interpreter','latex');
legend('Interpreter','latex');
[~, h] = contour(1./rhorange, refP, Trange,'LineStyle','-','DisplayName','REFPROP Isotherms','LineColor',refh.Color,'LineWidth',0.05);   
contour(1./rhorange, vdwP, Trange,'LineStyle','-','DisplayName','VDW Isotherms','LineColor',vdwh.Color,'LineWidth',0.05);   
ylim([0 1.1*refPsat(end)])
set(gca,'XScale','log');
pbaspect([1 1 1])

figure('Name','REFPROP_PT'); hold on;
refh = plot(Tsatrange, refPsat,'k','DisplayName','REFPROP Vapor Line','LineWidth',2);
xlabel('\textbf{Temperature,} $K$','interpreter','latex');
ylabel('\textbf{Pressure,} Pa','interpreter','latex');
legend('Interpreter','latex'); 
ylim([0 1.1*refPsat(end)])
set(gca,'XScale','log');
pbaspect([1 1 1])

if plotsurf
    figure('Name','REFPROP_FluidSurf'); hold on
    title('REFPROP Fluid Surface');
    surf(1./rhorange,Trange,refP,'EdgeColor','none','ButtonDownFcn',@onclick);
    surf(1./rhorange,Trange,refPl,'EdgeColor','none','ButtonDownFcn',@onclick);
    plot3(1./[refrhog; flip(refrhol)], [Tsatrange flip(Tsatrange)] ,[refPsat; flip(refPsat)],'k','DisplayName','REFPROP Vapor Dome','LineWidth',2);
    set(gca,'XScale','log');
    legend
    view(3);
    ylabel('Temperature, T');
    zlabel('Pressure, Pa');
    xlabel('Specific volume, v')

    figure('Name','VDW_FluidSurf'); hold on
    title('REFPROP Fluid Surface');
    surf(1./rhorange,Trange,vdwP,'EdgeColor','none','ButtonDownFcn',@onclick);
    plot3(1./[vdwrhog; flip(vdwrhol)], [vdwTsat; flip(vdwTsat)] ,[vdwPsat; flip(vdwPsat)],'k','DisplayName','VDW Vapor Dome','LineWidth',2);
    set(gca,'XScale','log');

    view(3);
    ylabel('Temperature, T');
    zlabel('Pressure, Pa');
    xlabel('Specific volume, v')
end

function onclick(~,~)
    persistent i
    if isempty(i); i = 0; end
    views = {[1 0 0], [0 -1 0], [0 0 1], 3};
    i = mod(i,numel(views)) ;
    i = i + 1;
    view(gca,views{i});
end


