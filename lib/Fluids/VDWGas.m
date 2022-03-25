classdef VDWGas < Gas
    properties
       Pc; % critical pressure, Pa
       Tc; % critical temperature, Tc
       a; % first virial coefficient, Pa*m^6/kg^2
       b; % second virial coefficient, m^3/kg
       mu_ref = 1E-5; % dynamic viscosity @ T_ref, Pa*s 
       T_ref = 273.15; % reference temp for dynamic viscosity, K

       P = 1E5; % pressure, Pa
       T = 298; % temperature, K
       rho = 1; % density, kg/m3
       cp = 1; % specific heat at constant pressure, J/kg/K
       cv = 1; % specific heat at constant volume, J/kg/K
       u = 1; % specific internal energy, J/kg
       h = 1; %specific enthalpy, J/kg
       s = 1; % specific entropy, J/kg/K
       mu = 1; % dynamic viscosity, Pa*s
       c = 1; % speed of sound, m/s
       mw = 1; % molecular weight, kg/mol
   end
    methods
        function obj = VDWGas(cv, mw, a, b, mu_ref, T_ref)
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
            obj.a = a/(mw^2);
            obj.b = b / mw;
            obj.Tc = 8*obj.a/27/obj.b/obj.R;
            obj.Pc = obj.a/27/(obj.b^2);
            if nargin > 4
                obj.mu_ref = mu_ref;
            end
            if nargin > 5
                obj.T_ref = T_ref;
            end
        end
        function update(obj)
            persistent warning_given
            if ((obj.P < obj.Pc) && (obj.T < obj.Tc)) && isempty(warning_given)
                warning_given = true;
               warning("VDWGas object is operating in vapor-liquid equlibrium state without representing the liquid component."); 
            end
            v = 1/obj.rho;
            obj.cp = obj.cv + obj.P*obj.R*(v^3)/(obj.P*(v^3)-obj.a*v+2*obj.a*obj.b);
            obj.c = sqrt(obj.R*obj.T/(obj.rho*obj.b-1)^2 - 2*obj.a*obj.rho);
            obj.u = obj.cv * obj.T - obj.a*obj.rho; 
            obj.h = obj.u + obj.P/obj.rho;
            obj.s = obj.R*(2.5+log((1-(obj.rho/obj.mw*obj.b))*obj.mw/obj.rho/obj.NA*(4*pi/3/(obj.hplanck^2)*obj.u*(obj.mw/obj.NA)^2)^(1.5)));
            obj.mu = obj.mu_ref*sqrt(obj.T/obj.T_ref); % hard sphere model
        end
        function update_PT(obj, P,T)
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
            obj.update();
        end
        function update_rhoP(obj,rho,P)
            obj.T = (P + obj.a*(rho^2))*(1/rho - obj.b)/obj.R;
            obj.P = P;
            obj.rho = rho;
            obj.update();
        end
        function update_rhoT(obj,rho,T)
           obj.P = obj.R*T/(1/rho-obj.b)-obj.a*(rho^2);
           obj.T = T;
           obj.rho = rho;
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
            obj.rho = rho;
            obj.T = (u+obj.a*rho)/obj.cv;
            obj.update_rhoT(rho,obj.T);
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
    end
end