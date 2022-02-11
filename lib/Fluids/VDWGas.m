classdef VDWGas < Gas
    properties
       Pc; % critical pressure, Pa
       Tc; % critical temperature, Tc
       a; % first virial coefficient, Pa*m^6/kg^2
       b; % second virial coefficient, m^3/kg
       mu_ref = 1E-5; % dynamic viscosity @ T_ref, Pa*s 
       T_ref = 273.15; % reference temp for dynamic viscosity, K
    end
    methods
        function obj = VDWGas(cv, mw, Tc, Pc, mu_ref, T_ref)
            % VDWGas(cv, mw, a, b)
            % Instantiate a Van Der Waal's gas object with the inputs:
            %   cv = specific heat capacity at constant volume, J/kg/K
            %   mw = molar weight, kg/mol
            %   Tc  = critical temperature, K
            %   Pc  = critical pressure, Pa
            % Optionally, include a reference viscosity and temperature for
            % simple sqrt(T) scaling of dynamic viscosity.
            obj = obj@Gas();
            obj.mw = mw;
            obj.cv = cv;
            obj.a = 27*(obj.R*Tc)^2 /(64*Pc);
            obj.b = (obj.R*Tc)/(8*Pc);
            obj.Tc = Tc;
            obj.Pc = Pc;
            if nargin > 4
                obj.mu_ref = mu_ref;
            end
            if nargin > 5
                obj.T_ref = T_ref;
            end
        end
        function s = update(obj)
            if ((obj.P < obj.Pc) && (obj.T < obj.Tc))
               warning("VDWGas object is operating in vapor-liquid equlibrium state without representing the liquid component."); 
            end
            obj.cp = obj.R*(obj.P + obj.a*obj.rho^2)/(obj.P - obj.a*obj.rho^2 + 2*obj.a*obj.b*obj.rho^3);
            obj.c = sqrt(obj.R*obj.T/(obj.rho*obj.b-1)^2 - 2*obj.a*obj.rho);
            obj.u = obj.cv * obj.T - obj.a*obj.rho; 
            obj.h = obj.u + obj.P/obj.rho;
            obj.s = obj.R*(2.5+log((1-(obj.rho/obj.mw*obj.b))*obj.mw/obj.rho/obj.NA*(4*pi/3/(obj.hplanck^2)*obj.u*(obj.mw/obj.NA)^2)^(1.5)));
            obj.mu = obj.mu_ref*sqrt(obj.T/obj.T_ref); % hard sphere model
            s = obj.state;
        end
        function s = update_PT(obj, P,T)
            obj.P = P;
            obj.T = T;
            vdw_roots = roots([-obj.a*obj.b, obj.a, - P*obj.b - obj.R*T, P]);
            real_vdw_roots = NaN(size(vdw_roots));
            for ii = 1:length(vdw_roots)
                if isreal(vdw_roots(ii))
                    real_vdw_roots(ii) = vdw_roots(ii);
                end
            end
            obj.rho = min(real_vdw_roots);
            s = obj.update();
        end
        function s = update_rhoP(obj,rho,P)
            obj.T = (P + obj.a*(rho^2))*(1/rho - obj.b)/obj.R;
            obj.P = P;
            obj.rho = rho;
            s = obj.update();
        end
        function s = update_rhoT(obj,rho,T)
           obj.P = obj.R*T/(1/rho-obj.b)-obj.a*(rho^2);
           obj.T = T;
           obj.rho = rho;
           s = obj.update();
        end
        function s = update_rhoh(obj,rho,h)
            xout = fzero(@(x) calc_resid(x,h,rho), [obj.P; obj.T]); % find solution iteratively
            obj.P = xout(1);
            obj.T = xout(2);
            s = obj.update();
            function r = calc_resid(x,h_goal,rho_goal)
                st = obj.update_PT(x(1),x(2));
                r = [h_goal - st.h; rho_goal-st.rho];
            end
        end
        function s = update_rhos(obj,rho,s)
            xout = fzero(@(x) calc_resid(obj,x,rho,s), [obj.P; obj.T]); % find solution iteratively
            obj.rho = xout(1);
            obj.P = xout(2);
            s = obj.update();
            function r = calc_resid(obj,x,rho_goal,s_goal)
                st = obj.update_PT(x(1),x(2));
                r = [rho_goal - st.rho; s_goal-st.s];
            end 
        end
        function s = update_sT(obj,s,T)
            xout = fzero(@(x) calc_resid(obj,x,s,T), [obj.rho; obj.P]); % find solution iteratively
            obj.rho = xout(1);
            obj.P = xout(2);
            s = obj.update();
            function r = calc_resid(obj,x,rho_goal,T_goal)
                st = obj.update_rhoP(x(1),x(2));
                r = [rho_goal - st.rho; T_goal-st.T];
            end  
        end
        function s = update_uT(obj,u,T)
           xout = fzero(@(x) calc_resid(obj,x,u,T), [obj.rho; obj.P]); % find solution iteratively
            obj.rho = xout(1);
            obj.P = xout(2);
            s = obj.update();
            function r = calc_resid(obj,x,u_goal,T_goal)
                st = obj.update_rhoP(x(1),x(2));
                r = [u_goal - st.rho; T_goal-st.T];
            end   
        end
        function s = update_hT(obj,h,T)
            xout = fzero(@(x) calc_resid(obj,x,h,T), [obj.rho; obj.P]); % find solution iteratively
            obj.rho = xout(1);
            obj.P = xout(2);
            s = obj.update();
            function r = calc_resid(obj,x,h_goal,T_goal)
                st = obj.update_rhoP(x(1),x(2));
                r = [h_goal - st.h; T_goal-st.T];
            end 
        end
        function s = update_hP(obj,h,P)
          	xout = fzero(@(x) calc_resid(obj,x,h,P), [obj.rho; obj.T]); % find solution iteratively
            obj.rho = xout(1);
            obj.T = xout(2);
            s = obj.update();
            function r = calc_resid(obj,x,h_goal,P_goal)
                st = obj.update_rhoT(x(1),x(2));
                r = [h_goal - st.h; P_goal-st.P];
            end
        end
    end
end