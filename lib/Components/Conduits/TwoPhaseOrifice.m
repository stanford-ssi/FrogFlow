classdef TwoPhaseOrifice < Orifice
    % TODO:
    % - clip inputs with warning rather than extrapolating in a "check"
    %   function that modifies variables by returning the inputs after
    %   clipping
    % - pull from SatFluid.Tmin, Tmax to define temp range
    % - shove the range data into the flow object
    % - make static functions with persistent vars that save interpolation
    %   function for faster lookups
    % - add warning if upstream fluid is not same type as used for flow
    %   calc (add this to the general "check" function that also confirms
    %   in-range)
    properties(Constant, Hidden)
        Pupnorm_range = [1 3]; % min/max upstream pressure range normalized by vapor pressure 
        Pdownnorm_range = [0 1]; % min/max downstream pressure range normalized by upstream pressure
        n = 100; % K, grid size in one dimension
        flow = DataHandle(); % struct for storing flow information:
              %     - Ghem: 3D grid of HEM model mass flux
              %     - Gcrit: 2D grid of critical "choked" values from 
              %              ChokedHEM model 
              %     - T1: 1D array of upstream temp values
              %     - T2: 2D meshgrid of upstream temp (const dim 2)
              %     - T3: 3D meshgrid of upstream temp (const dim 2)
              %     - Pv: 1D grid vapor pressure corresponding to upstream temp
              %     - Pup2: 2D meshgrid of upstream pressures normalized by
              %             vapor pressure (const dim 1)
              %     - Pup3: 3D meshgrid of upstream pressures (const dim 1)
              %     - Pdown1: 1D array of downstream pressure values
              %               normalized by upstream pressure
              %     - Pdown3: 3D meshgrid of downstream pressure (const dim 3)
              %     - Pcrit: 2D grid of critical downstream pressure at
              %              which choked flow occurs in ChokedHEM model,
              %              normalized by upstream pressure
              %     - choked: 3D grid of whether a given T/Pup/Pdown combo
              %              is choked in the ChokedHEM model
              %     - fluid: satliq used for calculating these flow
              %              parameters

       type_map = {{'IncompressibleLiquid',@Orifice.flowdot_SPI};
                   {'Gas',@Orifice.flowdot_gas};
                   {'SatFluid',@Orifice.flowdot_HEMChoked};
                   };
       comp_map = {{'ChokedHEM', @TwoPhaseOrifice.flowdot_ChokedHEM};
                   {'HEM', @TwoPhaseOrifice.flowdot_HEM};
                   {'SPI', @Orifice.flowdot_SPI};
                   {'Dyer', @TwoPhaseOrifice.flowdot_Dyer}; 
                   };
    end 
    methods      
        function obj = TwoPhaseOrifice(Cd,A,varargin)
            clear TwoPhaseOrifice.range_check
            if nargin == 2
                type = 'SPI';
            elseif nargin > 2
                type = varargin{1};
            end
            % Check for ChokedHEM input type
            if (isstring(type) || ischar(type)) && ~strcmpi(type,'SPI') % SPI model doesn't need fluids for calc
                if nargin < 5
                    error('You must pass both the saturated gas and liquid for the TwoPhaseOrifice model.')
                elseif isa(varargin{2},'Gas')
                    satgas = varargin{2};
                    satliq = varargin{3};
                else
                    satliq = varargin{2};
                    satgas = varargin{3};
                end
            elseif isa(type,'SatFluid') 
                if nargin <= 3 
                    error('You must pass both the saturated gas and liquid for the TwoPhaseOrifice model.')
                elseif isa(type,'Gas')
                    satgas = type;
                    satliq = varargin{2};
                else
                    satliq = type;
                    satgas = varargin{2};
                end
                type = 'ChokedHEM'; % default model
            end
            flowfunc = [];
            for i = 1:numel(TwoPhaseOrifice.comp_map)
                if strcmpi(TwoPhaseOrifice.comp_map{i}{1},type)
                    flowfunc = TwoPhaseOrifice.comp_map{i}{2};
                    break;
                end
            end
            if isempty(flowfunc)
                error('Did not find a matching type for saturated fluid flow.');
            end
            obj@Orifice(Cd,A,{'SatFluid',flowfunc});
            if ~strcmpi(type,'SPI') && isempty(obj.flow.data)
                obj.flow.data = obj.calccritflow(satgas,satliq);
            end
            warning('on',"TwoPhaseOrifice:FluidWarning")
            warning('on','TwoPhaseOrifice:RangeWarning');
       end
    end
    methods(Static)
        function flowi = calccritflow(satgas,satliq)
            persistent flow % store these variables for this orifice to prevent re-calc on each run
            if isempty(flow)
                % store initial temperature to return fluid to its original state
                Tgas = satgas.T;
                Tliq = satliq.T; 

                % generate grids
                T1 = linspace(satliq.Tmin,satliq.Tmax,TwoPhaseOrifice.n);
                Pupnormrange =  linspace(TwoPhaseOrifice.Pupnorm_range(1),TwoPhaseOrifice.Pupnorm_range(2),TwoPhaseOrifice.n);
                Pdownnormrange =  linspace(TwoPhaseOrifice.Pdownnorm_range(1),TwoPhaseOrifice.Pdownnorm_range(2),TwoPhaseOrifice.n);
                [T2, Pup2] = meshgrid(T1,Pupnormrange);
                [T3, Pup3, Pdown3] = meshgrid(T1,Pupnormrange,Pdownnormrange);
                Ghem = zeros(size(T3));
                Pv = zeros(size(T1));
                % Calc HEM flow at each temperature, upstream pressure,
                % downstream pressure
                for i = 1:length(T1)
                    % Set upstream state
                    satliq.update_T(T1(i));
                    Psat = satliq.P; % vapor pressure (saturation)
                    Pv(i) = Psat;
                    P1 = squeeze(Pup3(:,i,:)*Psat);
                    P2 = squeeze(Pdown3(:,i,:)).*P1;
                    % Get upstream properties of interest 
                    rho_l_up = satliq.rho*ones(size(P1));
                    s_l_up = satliq.s*ones(size(P1));
                    % for now, calculate h as projection off sat value
                    h1 = satliq.h + (P1-Psat)/satliq.rho ;
                    % in the future, calculate off-saturation state
%                     h1 = ones(size(P1));
%                     for i = 1:ChokedHEMOrifice.n % for each upstream pressure
%                         satliq.update_PT(P1(1,i)); % P1 constant across first dimension
%                         h(i,:) = satliq.h;
%                     end
                    
                    
                    % Get downstream propertes of interest
                    rho_l_down = zeros(size(P2));
                    rho_g_down = zeros(size(P2));
                    s_l_down = zeros(size(P2));
                    s_g_down = zeros(size(P2));
                    h_l_down = zeros(size(P2));
                    h_g_down = zeros(size(P2));

                    for j = 1:length(Pdownnormrange) % Populate downstream variables of size P2
                        p2 = P2(1,j);
                        % Set downstream state
                        satliq.update_P(p2);
                        satgas.update_P(p2);
                        rho_l_down(:,j) = satliq.rho;
                        rho_g_down(:,j) = satgas.rho;
                        h_l_down(:,j) = satliq.h;
                        h_g_down(:,j) = satgas.h;
                        s_l_down(:,j) = satliq.s;
                        s_g_down(:,j) = satgas.s;
                    end
                    % Entropy diff
                    ds_ld_lu = s_l_down - s_l_up;
                    ds_ld_gd = s_l_down - s_g_down;
                    % Calculate mass fraction of gas to conserve entropy
                    % and limit out-of-physical-range
                    x = ds_ld_lu./ds_ld_gd;
                    rho_l_down(x<0) = rho_l_up(x<0);
                    h_l_down(x<0) = h1(x<0) + (P2(x<0)-P1(x<0))./rho_l_up(x<0);
                    x(x<0) = 0;

                    rho2 = 1./(x.*(1./rho_g_down)+(1-x).*(1./rho_l_down));
                    h2 = x.*h_g_down + (1-x).*h_l_down;

                    Ghem(:,i,:) = rho2.*sqrt(2*(h1-h2));
                end
                % Calculate where flow is choked in ChokedHEM model
                [Gcrit, icrit] = max(Ghem, [], 3,'linear');
                Pcrit = Pdown3(icrit);
                choked = Pdown3 <= repmat(Pcrit,1,1,size(Pdown3,3));

                % return fluids to initial state
                satliq.update_T(Tliq); 
                satgas.update_T(Tgas)
                
                % populate struct
                flow.Ghem = Ghem;
                flow.Gcrit = Gcrit;
                flow.choked = choked;
                flow.T1 = T1;
                flow.T2 = T2;
                flow.T3 = T3;
                flow.Pv = Pv;
                flow.Pup2 = Pup2;
                flow.Pup3 = Pup3;
                flow.Pdown3 = Pdown3;
                flow.Pcrit = Pcrit;
                flow.fluid = satliq;
            end
            flowi = flow;
        end
    end
    methods(Static)
        function [mdot, Udot,varargout] = flowdot_ChokedHEM(upstream, downstream,Cd,A,mult)
            Pup = upstream.P;
            Pdown = downstream.P;
            Tup = upstream.T;
            % 1D lookup of vapor pressure
            Pv = interp1(TwoPhaseOrifice.flow.data.T1,TwoPhaseOrifice.flow.data.Pv,Tup,'linear','extrap');
            [Pup, Tup, Pdown] = TwoPhaseOrifice.range_check(Tup,Pup,Pdown,Pv,upstream);
            % check if choked 
            Pcrit = interp2(TwoPhaseOrifice.flow.data.T2,TwoPhaseOrifice.flow.data.Pup2,TwoPhaseOrifice.flow.data.Pcrit,Tup,max(1,Pup/Pv));
            % perform lookup on upstream pressure, upstream temp
            if Pdown/Pup <= Pcrit
                % Choked, use critical flow
                G = interp2(TwoPhaseOrifice.flow.data.T2,TwoPhaseOrifice.flow.data.Pup2,TwoPhaseOrifice.flow.data.Gcrit,Tup,max(1,Pup/Pv));
            else
                % Not choked, use HEM flow
                G = interp3(TwoPhaseOrifice.flow.data.T3,TwoPhaseOrifice.flow.data.Pup3,TwoPhaseOrifice.flow.data.Pdown3,TwoPhaseOrifice.flow.data.Ghem,Tup,max(1,Pup/Pv),Pdown/Pup);
            end
            mdot = mult*Cd*A*G;
            Udot = upstream.h*mdot;
            if nargout > 2 % do vargout
                varargout{1} = Pdown/Pup >= Pcrit;
                varargout{2} = Pup-Pdown;
                varargout{3} = mult;
            end
        end
        function [mdot, Udot,varargout] = flowdot_HEM(upstream,downstream,Cd,A,mult)
            Pup = upstream.P;
            Pdown = downstream.P;
            Tup = upstream.T;
            % 1D lookup of vapor pressure
            Pv = interp1(TwoPhaseOrifice.flow.data.T1,TwoPhaseOrifice.flow.data.Pv,Tup,'linear','extrap');
            [Pup, Tup, Pdown] = TwoPhaseOrifice.range_check(Tup,Pup,Pdown,Pv,upstream);
            % perform lookup on upstream pressure, upstream temp, downstream pressure
            G = interp3(TwoPhaseOrifice.flow.data.T3,TwoPhaseOrifice.flow.data.Pup3,TwoPhaseOrifice.flow.data.Pdown3,TwoPhaseOrifice.flow.data.Ghem,Tup,max(1,Pup/Pv),Pdown/Pup);
            mdot = mult*Cd*A*G;
            Udot = upstream.h*mdot;
            if nargout > 2 % do vargout
                varargout{1} = 0;
                varargout{2} = Pup-Pdown;
                varargout{3} = mult;
            end
        end
        function [mdot, Udot,varargout] = flowdot_Dyer(upstream,downstream,Cd,A,mult)
            Pup = upstream.P;
            Pdown = downstream.P;
            rhoup = upstream.rho;
            Tup = upstream.T;
            % 1D lookup of vapor pressure
            Pv = interp1(TwoPhaseOrifice.flow.data.T1,TwoPhaseOrifice.flow.data.Pv,Tup,'linear','extrap');
            [Pup, Tup, Pdown] = TwoPhaseOrifice.range_check(Tup,Pup,Pdown,Pv,upstream);
            % perform lookup on upstream pressure, upstream temp, downstream pressure
            Ghem = interp3(TwoPhaseOrifice.flow.data.T3,TwoPhaseOrifice.flow.data.Pup3,TwoPhaseOrifice.flow.data.Pdown3,TwoPhaseOrifice.flow.data.Ghem,Tup,max(1,Pup/Pv),Pdown/Pup);
            Gspi = sqrt(2*rhoup*(Pup-Pdown));
            k = sqrt((Pup-Pdown)/(Pv-Pdown));
            G = (k*Gspi + Ghem)/(1+k);
            mdot = Cd*A*G;
            Udot = upstream.h*mdot;

            if nargout > 2 % do vargout
                varargout{1} = 0;
                varargout{2} = Pup-Pdown;
                varargout{3} = mult;
            end
        end
        function [Pup, Tup, Pdown] = range_check(Tup,Pup,Pdown,Pv,upstream)
            % Check fluid compatibility
            if ~strcmpi(class(upstream),class(TwoPhaseOrifice.flow.data.fluid))
                warning("TwoPhaseOrifice:FluidWarning","The fluid flowing (%s) is not compatible with the current two-phase calculations (%s).\nClear workspace variables to force a re-calculation of flow variables.",class(upstream),class(TwoPhaseOrifice.flow.data.fluid));
                warning('off',"TwoPhaseOrifice:FluidWarning")
            end
            % Check range
            Pupnorm = Pup/Pv;
            Pdownnorm = Pdown/Pup;

            if Pupnorm < TwoPhaseOrifice.Pupnorm_range(1) || Pupnorm > TwoPhaseOrifice.Pupnorm_range(2)
                Pup = Pv*min(max(Pupnorm,TwoPhaseOrifice.Pupnorm_range(1)),TwoPhaseOrifice.Pupnorm_range(2));
                warning('TwoPhaseOrifice:RangeWarning','Upstream pressure ran out of the range of pre-calculated values. Value is clipped to the calculated range.');
                warning('off','TwoPhaseOrifice:RangeWarning');
            elseif Tup < TwoPhaseOrifice.flow.data.fluid.Tmin || Tup > TwoPhaseOrifice.flow.data.fluid.Tmax
                Tup = min(max(Tup,TwoPhaseOrifice.flow.data.fluid.Tmin),TwoPhaseOrifice.flow.data.fluid.Tmax);
                warning('TwoPhaseOrifice:RangeWarning','Upstream temperature ran out of the range of pre-calculated values. Value is clipped to the calculated range.');
                warning('off','TwoPhaseOrifice:RangeWarning');
            elseif Pdownnorm < TwoPhaseOrifice.Pdownnorm_range(1) || Pdownnorm > TwoPhaseOrifice.Pdownnorm_range(2)
                Pdown = Pup*min(max(Pdownnorm,TwoPhaseOrifice.Pdownnorm_range(1)),TwoPhaseOrifice.Pdownnorm_range(2));
                warning('TwoPhaseOrifice:RangeWarning''Upstream pressure ran out of the range of pre-calculated values. Value is clipped to the calculated range.');
                warning('off','TwoPhaseOrifice:RangeWarning');
            end
        end
    end
end