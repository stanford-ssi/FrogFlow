classdef (Abstract) VDWFluid < Fluid & SatFluid
    % gas following the equation: (P + a rho^2)(1-rho b)=rho R T
    properties(Hidden)
       Pc; % critical pressure, Pa
       Tc; % critical temperature, Tc
       rhoc; % critical density, rhoc
       Tmin;
       Tmax;
    end
    properties(Abstract, Constant, Hidden) % instantiate these in final, non-abstract classdef
       Tr; % array of reduced temp values at which saturation has been calced
       Pr; % array of reduced pressure values for saturation
       rhor; % array of reduced [rhomin rhomax] defining regime of equal-area law
    end
    properties(Access=protected)
       a; % first virial coefficient, Pa*m^6/kg^2
       b; % second virial coefficient, m^3/kg
       mu_ref; % dynamic viscosity @ T_ref, Pa*s 
       T_ref % reference temp for dynamic viscosity, K
       type; % type : 1 = gas, 2 = liquid
    end
    methods(Abstract)
        satcalc(obj); % perform the saturation calc using calcsatcurve(), defined below (use persistent vars to avoid re-calcing each run)
%         function satcalc(obj)
%             % Function specific to each type, uses persistent to avoid
%             % re-calcing the saturation values on each sim run. Use    
%             % <clear all> to force re-calc.
%             persistent Tr Pr rhor
%             if isempty(Tr)
%                 [Tr, Pr, rhor] = obj.calcsatcurve();
%             end
%             obj.Tr.data = Tr;
%             obj.Pr.data = Pr;
%             obj.rhor.data = rhor;
%         end
    end
    methods
        function obj = VDWFluid(cv, mw, a, b, type, mu_ref, T_ref)
            % VDWFluid(cv, mw, a, b,muref, Tref, type)
            % Instantiate a Van Der Waal's gas object with the inputs:
            %   cv = specific heat capacity at constant volume, J/kg/K
            %   mw = molar weight, kg/mol
            %   a  = first Van der Waal coefficient, m^6*Pa/mol
            %   b = second Van der Waal coefficient, m^3/mol
            % type indicates whether a gas (1) or liquid (2) - identical
            % above critical temp.
            % Optionally, include a reference viscosity and temperature for
            % simple sqrt(T) scaling of dynamic viscosity.
            if isstring(type) || ischar(type)
                if strcmpi(type,'vapor') || strcmpi(type,'gas') 
                    type = 1;
                else
                    type = 2;
                end
            end
            obj = obj@Fluid();
            obj.mw = mw;
            obj.cv = cv;
            obj.a = a/(mw^2); % convert to mass-based
            obj.b = b / mw; % convert to mass-based
            obj.type = type;
            obj.Tc = 8*obj.a/27/obj.b/obj.R;
            obj.Pc = obj.a/27/(obj.b^2);
            obj.rhoc = 1/3/obj.b;

            obj.k = 0.02; % thermal conductivity, W/m/K (just an estimate placeholder, needs real data)
            if nargin > 5
                obj.mu_ref = mu_ref;
            end
            if nargin > 6
                obj.T_ref = T_ref;
            end
            obj.satcalc(); % calculate saturation values, if it hasn't been done
            obj.Tmax = obj.Tc;
            obj.Tmin = obj.Tc*obj.Tr.data(1);
        end
        % STATE UPDATING --------------------------------------------------
        function update(obj)
            % Assumes rho, P, and T have been updated
            v = 1/obj.rho;
            obj.cp = obj.cv + obj.R; % obj.P*obj.R*(v^3)/(obj.P*(v^3)-obj.a*v+2*obj.a*obj.b);
            obj.c = sqrt(obj.R*obj.T/(obj.rho*obj.b-1)^2 - 2*obj.a*obj.rho);
            obj.u = obj.cv * obj.T - obj.a*obj.rho; 
            obj.h = obj.u + obj.P*v;
            obj.s = obj.R*(2.5+log((v-obj.b)*(obj.u+obj.a/v)^1.5));
            obj.mu = obj.mu_ref*sqrt(obj.T/obj.T_ref); % hard sphere model
            obj.beta = obj.R*(v^2)*(v-obj.b)/(obj.R*obj.T*(v^3)-2*obj.a*(v-obj.b)^2);
        end
        function update_PT(obj, P,T)
            obj.P = P;
            obj.T = T;
            vdw_roots = roots([-obj.a*obj.b, obj.a, - P*obj.b - obj.R*T, P]);
            vdw_roots = vdw_roots(imag(vdw_roots)==0);
            vdw_roots = sort(vdw_roots);
            if length(vdw_roots) > 2
                obj.rho = vdw_roots(2); % true state value inside sat curve
            elseif length(vdw_roots) > 1
                obj.rho = vdw_roots(obj.type);
            else
                obj.rho = vdw_roots(1);
            end
            obj.update();
        end
        function update_rhoP(obj,rho,P)
            obj.T = (P + obj.a*(rho^2))*(1/rho - obj.b)/obj.R;
            obj.P = P;
            obj.rho = rho;
            obj.update();
        end
        function update_rhoT(obj,rho,T)
           obj.T = T; 
           obj.rho = rho;
           obj.P = (rho*obj.R*T/(1-rho*obj.b))-obj.a*(rho^2);
           obj.update();
        end
        function update_rhoh(obj,rho,h)
            Phold = obj.P;
            Thold = obj.T;
            [~,~,exitflag] = fminsearch(@(x) calc_resid(x,h,rho), [obj.P; obj.T]); % find solution iteratively
            if exitflag < 1
                obj.update_PT(Phold,Thold);
                warning("VDW Solver failed to find function zero.")
            end
            obj.update();
            function r = calc_resid(x,h_goal,rho_goal)
                obj.update_PT(x(1),x(2));
                r = norm([h_goal - obj.h; rho_goal-obj.rho]);
            end
        end
        function update_rhou(obj,rho,u)
            T = (u + obj.a*rho)/obj.cv;
            obj.update_rhoT(rho,T);
        end
        function update_rhos(obj,rho,s)
            Phold = obj.P;
            Thold = obj.T;
            [~,~,exitflag] = fminsearch(@(x) calc_resid(obj,x,rho,s), [obj.P; obj.T]); % find solution iteratively
            if exitflag < 1
                obj.update_PT(Phold,Thold);
                warning("VDW Solver failed to find function zero.")
            end
            obj.update();
            function r = calc_resid(obj,x,rho_goal,s_goal)
                obj.update_PT(x(1),x(2));
                r = norm([rho_goal - obj.rho; s_goal-obj.s]);
            end 
        end
        function update_sT(obj,s,T)
            Phold = obj.P;
            rhohold = obj.rho;
            [~,~,exitflag] = fminsearch(@(x) calc_resid(obj,x,s,T), [obj.rho; obj.P]); % find solution iteratively
            if exitflag < 1
                obj.update_rhoP(rhohold,Phold);
                warning("VDW Solver failed to find function zero.")
            end
            obj.update();
            function r = calc_resid(obj,x,rho_goal,T_goal)
                obj.update_rhoP(x(1),x(2));
                r = norm([rho_goal - obj.rho; T_goal-obj.T]);
            end  
        end
        function update_uT(obj,u,T)
           Phold = obj.P;
           rhohold = obj.rho;
           [~,~,exitflag] = fminsearch(@(x) calc_resid(obj,x,u,T), [obj.rho; obj.P]); % find solution iteratively
           if exitflag < 1
                obj.update_rhoP(rhohold,Phold);
                warning("VDW Solver failed to find function zero.")
           end
            obj.update();
            function r = calc_resid(obj,x,u_goal,T_goal)
                st = obj.update_rhoP(x(1),x(2));
                r = norm([u_goal - st.rho; T_goal-st.T]);
            end   
        end
        function update_uP(obj,u,P)
           Thold = obj.T;
           rhohold = obj.rho;
           [~,~,exitflag] = fminsearch(@(x) calc_resid(obj,x,u,P), [obj.rho; obj.T]); % find solution iteratively
           if exitflag < 1
                obj.update_rhoT(rhohold,Thold);
                warning("VDW Solver failed to find function zero.")
           end
            obj.update();
            function r = calc_resid(obj,x,u_goal,P_goal)
                st = obj.update_rhoT(x(1),x(2));
                r = norm([u_goal - st.rho; P_goal-st.P]);
            end   
        end
        function update_hT(obj,h,T)
            Phold = obj.P;
            rhohold = obj.rho;
            [~,~,exitflag] = fminsearch(@(x) calc_resid(obj,x,h,T), [obj.rho; obj.P]); % find solution iteratively
            if exitflag < 1
                obj.update_rhoP(rhohold,Phold);
                warning("VDW Solver failed to find function zero.")
            end
            obj.update();
            function r = calc_resid(obj,x,h_goal,T_goal)
                obj.update_rhoP(x(1),x(2));
                r = norm([h_goal - obj.h; T_goal-obj.T]);
            end 
        end
        function update_hP(obj,h,P)
            rhohold = obj.rho;
            Thold = obj.T;
          	[~,~,exitflag] = fminsearch(@(x) calc_resid(obj,x,h,P), [obj.rho; obj.T]); % find solution iteratively
            if exitflag < 1
                obj.update_rhoT(rhohold,Thold);
                warning("VDW Solver failed to find function zero.")
            end
            obj.rho = xout(1);
            obj.T = xout(2);
            obj.update();
            function r = calc_resid(obj,x,h_goal,P_goal)
                obj.update_rhoT(x(1),x(2));
                r = norm([h_goal - obj.h; P_goal-obj.P]);
            end
        end

        % SATURATED UPDATING ----------------------------------------------
        function update_T(obj,T)
            if isempty(obj.Tr.data)
                obj.satcalc();
            end
            if T < obj.Tr.data(1)*obj.Tc || T > obj.Tc
                error('VDWGas went above critical temp or below edge of calculated vapor dome.')
            end
            obj.T = T;
            obj.P = obj.Pc*interp1(obj.Tr.data,obj.Pr.data,T/obj.Tc); % find sat pressure
            obj.rho = obj.rhoc*interp1(obj.Tr.data,obj.rhor.data(:,obj.type),T/obj.Tc); % find sat density
            obj.update();
        end
        function update_P(obj,P)
            if isempty(obj.Tr.data)
                obj.satcalc();
            end
            if P < obj.Pr.data(1)*obj.Pc || P > obj.Pc
                error('VDWGas went above critical pressure or below edge of calculated vapor dome.')
            end
            obj.P = P;
            obj.T = obj.Tc*interp1(obj.Pr.data,obj.Tr.data,P/obj.Pc); % find sat temp
            obj.rho = obj.rhoc*interp1(obj.Pr.data,obj.rhor.data(:,obj.type),P/obj.Pc); % find sat density
            obj.update();
        end

        % STATE DERIVATIVES -----------------------------------------------
        function dpdt = dPdT(obj)
            dpdt = obj.R*obj.rho/(1-obj.rho*obj.b);
        end
        function dpdrho = dPdrho(obj)
            dpdrho = (obj.R*obj.T + obj.P*obj.b - 2*obj.a*obj.rho)/(1-bj.rho*obj.b);
        end
        function dudrh = dudrho(obj)
            dudrh = -obj.cv*obj.P/(obj.rho^2)/obj.R;
        end
        function dudt = dudT(obj)
            dudt = obj.cv;
        end

        % MAXWELL AREA RULE FOR SAT CURVE ---------------------------------
                    % calc equal area limits and values at limits
            % (i.e. saturation vals)
        function [Tr, Pr, rhor] = calcsatcurve(obj)
            logbase = 30; % logarithm base for logspace of reduced temp (needs to be dense near Tr = 1)
            num_steps = 50; % number of points to calc
            Tr = log10(linspace(logbase^0.1,logbase,num_steps))/log10(logbase); 
            Pr = zeros(size(Tr));
            rhor = zeros(length(Tr),2);
            opts = optimoptions('fmincon','Display','notify','OptimalityTolerance',1E-10,'StepTolerance',1E-10);
            for i = 1:length(Tr)
                if i == 1 
                    P0 = 0;
                else
                    P0 = Pr(i-1);
                end
                if obj.Tr == 1
                    Pr(i) = 1;
                    rhor(i,:) = [1 1];
                else
                    Pr(i) = fmincon(@(Pr) get_maxwell_pressure(Pr,Tr(i)),P0,[],[],[],[],0.9*P0,1,[],opts);
                    if abs(Pr(i) - 1) < 0.1 && Tr(i) < 0.9
                        Pr(i) = 0;
                    end
                    vdw_roots = roots([Pr(i), -(Pr(i)+8*Tr(i))/3, 3, -1]);
                    P = Pr(i);
                    vdw_roots = sort(1./real(vdw_roots));
                    if length(vdw_roots) == 2
                        rhor(i,2) = vdw_roots(end);
                        rhor(i,1) = 1E-2;
                    else
                        rhor(i,:) = [vdw_roots(1) vdw_roots(end)];
                    end
                end
            end
            % trim dome below zero
            lastidx = max(1, find(Pr,1,"first") - 1);
            Tr = Tr(lastidx:end);
            Pr = Pr(lastidx:end);
            rhor = rhor(lastidx:end,:);
            function delta = get_maxwell_pressure(Pr,Tr)
                % solve reduced form
                vdw_root = roots([Pr, -(Pr+8*Tr)/3, 3, -1]);
                if sum(abs(imag(vdw_root))) > 0 % if some components complex
                    vdw_root = vdw_root(imag(vdw_root)~=0);
                    delta = abs(imag(vdw_root(1))) + 1E-3; % move towards non-imag root
                    return
                end
                vdw_root = sort(vdw_root);
                vg = vdw_root(end); % largest specific vol is gas
                vl = vdw_root(1); % smallest specific vol is liquid
                % https://en.wikipedia.org/wiki/Maxwell_construction
                delta = 8*Tr/3*log((3*vl-1)/(3*vg-1))-8*Tr*(vl/(3*vl-1)-vg/(3*vg-1)) + 6/vl - 6/vg;
                delta = abs(delta);
            end
        end
    end
end