classdef IdealGas < Gas
    properties
       mu_ref = 1E-5; % dynamic viscosity @ T_ref, Pa*s 
       T_ref = 273.15; % reference temp for dynamic viscosity, K
    end
    methods
        function obj = IdealGas(gamma,mw,mu_ref,T_ref)
            obj = obj@Gas();
            obj.mw = mw;
            obj.cv = obj.R/(gamma-1);
            obj.cp = obj.cv + obj.R;
            if nargin > 2
                obj.mu_ref = mu_ref;
            end
            if nargin > 3
                obj.T_ref = T_ref;
            end
        end
        function update(obj)
            obj.update_PT(obj.P, obj.T);
        end
        function update_PT(obj, P,T)
            obj.P = P;
            obj.T = T;
            obj.rho = P/obj.R/T; % ideal gas law
            obj.c = sqrt(obj.gamma*P/obj.rho);
            obj.u = obj.cv * T; 
            obj.h = obj.cp * T;
            obj.s = obj.R*(2.5+log(obj.mw/obj.rho/obj.NA*(4*pi/3/(obj.hplanck^2)*obj.u*(obj.mw/obj.NA)^2)^(1.5)));
            obj.mu = obj.mu_ref*sqrt(obj.T/obj.T_ref); % hard sphere model
        end
        function update_rhoP(obj,rho,P)
            obj.T = P/obj.R/rho;
            obj.P = P;
            obj.rho = rho;
            obj.c = sqrt(obj.gamma*P/obj.rho);
            obj.u = obj.cv * T; 
            obj.h = obj.cp * T;
            obj.s = obj.R*(2.5+log(obj.mw/obj.rho/obj.NA*(4*pi/3/(obj.hplanck^2)*obj.u*(obj.mw/obj.NA)^2)^(1.5)));
            obj.mu = obj.mu_ref*sqrt(obj.T/obj.T_ref); % hard sphere model
        end
        function update_rhoT(obj,rho,T)
           obj.T = T;
           obj.rho = rho;
           obj.P = rho*T*obj.R;
           obj.c = sqrt(obj.gamma*P/obj.rho);
           obj.u = obj.cv * T; 
           obj.h = obj.cp * T;
           obj.s = obj.R*(2.5+log(obj.mw/obj.rho/obj.NA*(4*pi/3/(obj.hplanck^2)*obj.u*(obj.mw/obj.NA)^2)^(1.5)));
           obj.mu = obj.mu_ref*sqrt(obj.T/obj.T_ref); % hard sphere model
        end
        function update_sT(~)
           error("This update method not supported - state variables not independent."); 
        end
        function update_rhos(~)
           error("This update method not supported - state variables not independent."); 
        end
        function update_uT(~)
           error("This update method not supported - state variables not independent."); 
        end
    end
end