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
        function s = update_sT(~)
           error("This update method not supported."); 
        end
        function s = update_rhos(~)
           error("This update method not supported."); 
        end
        function s = update_uT(~)
           error("This update method not supported."); 
        end
    end
end