classdef ChokedHEMOrifice < Orifice
    properties(Constant, Hidden)
        T_range = [180 310]; % K, min/max temp of flow calcs
        Pupnorm_range = [1 3]; % min/max upstream pressure range normalized by vapor pressure
        Pdownnorm_range = [0 1]; % min/max downstream pressure range normalized by upstream pressure
        n = 100; % K, grid size in one dimension
    end
    properties(Hidden)
        G; % 3D-array of mass flux
        T; % 3D grid of temperature values
        Pup; % 3D grid of upstream pressure
        Pdown; % 3D grid of downstream pressure
        critflow; % struct for storing critical flow information
    end

    properties(Constant,Hidden)
       type_map = {{'IncompressibleLiquid',@Orifice.flowdot_SPI};
                   {'Gas',@Orifice.flowdot_gas};
                   {'SatFluid',@Orifice.flowdot_HEMChoked};};
    end
    methods      
       function obj = ChokedHEMOrifice(Cd,A,satgas,satliq)
            obj@Orifice(Cd,A,{'SatFluid',ChokedHEMOrifice.flowdot_ChokedHEM});
            [obj.G, obj.T, obj.Pup, obj.Pdown, obj.critflow] = obj.calccritflow(satgas,satliq);
       end
    end
    methods(Static)
        function [Gi, Ti, Pupi, Pdowni, critflowi] = calccritflow(satgas,satliq)
            persistent G T Pvap Pup Pdown critflow
            if isempty(G)
                % store initial temperature to return fluid to its original state
                Tgas = satgas.T;
                Tliq = satliq.T; 
                % generate grids
                Trange = linspace(ChokedHEMOrifice.T_range(1),ChokedHEMOrifice.T_range(2),ChokedHEMOrifice.n);
                Puprange =  linspace(ChokedHEMOrifice.Pupnorm_range(1),ChokedHEMOrifice.Pupnorm_range(2),ChokedHEMOrifice.n);
                Pdownrange =  linspace(ChokedHEMOrifice.Pdownnorm_range(1),ChokedHEMOrifice.Pdownnorm_range(2),ChokedHEMOrifice.n);
                [T, Pupnorm, Pdownnorm] = meshgrid(Trange,Puprange,Pdownrange);
                G = zeros(size(T));
                Pvap = zeros(size(T));
                % Calc flow at each temperature
                for i = 1:length(Trange)
                    % Set upstream state
                    satliq.update_T(Trange(i));
                    Psat = satliq.P; % vapor pressure (saturation)
                    P1 = Puprange*Psat; % un-normalized upstream pressure
                    P2 = Pdownrange.*P1; % un-normalized downstream pressure
                    [P1, P2] = meshgrid(P1, P2);

                    % Get upstream properties of interest (no for loop
                    % needed, matrix math)
                    rho_up = satliq.rho*ones(size(P1));
                    % liq sat density (make size of P1)
                    % liq sat entropy (make size of P1)
                    % liq enthalpy (extended using Puprange off saturation)
                    
                    % Get downstream propertes of interest
                    rho_l_down = zeros(size(P2));
                    rho_g_down = zeros(size(P2));
                    s_l_down = zeros(size(P2));
                    s_g_down = zeros(size(P2));
                    h_l_down = zeros(size(P2));
                    h_g_down = zeros(size(P2));

                    for j = 1:length(Pdownrange) % Populate downstream variables of size P2
                        p2 = P2(j,1);
                        % Set downstream state
                        satliq.update_P(p2);
                        satgas.update_P(p2);
                        % downstream liq+gas density
                        % downstream enthalpy
                        % downstream liq+gas entropy
                        
                        % Calc crit flow
                    end

                    Pvap(:,i,:) = Psat;
                end
                Pup = Pupnorm.*Pvap;
                Pdown = Pdownnorm.*Pup;
                satliq.update_T(Tliq); % return fluids to initial state
                satgas.update_T(Tgas)
            end
            Gi = G;
            Ti = T;
            Pupi = Pup;
            Pdowni = Pdown;
            critflowi = critflow;
       end
        function [mdot, Udot,varargout] = flowdot_ChokedHEM(upstream, downstream,Cd,A,mult)
            % Use pre-calculated values of mass flux to compute output
            
        end
    end
end