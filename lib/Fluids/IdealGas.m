classdef IdealGas < Gas
    properties
       mu_ref = 1E-5; % dynamic viscosity @ T_ref, Pa*s 
       T_ref = 273.15; % reference temp for dynamic viscosity, K
    end
    methods
        function obj = IdealGas(gamma,mw,mu_ref,T_ref)
            obj = obj@Gas();
            disp(Gas)
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
        function s = update(obj)
            obj.rho = obj.P/obj.R/obj.T; % ideal gas law
            obj.c = sqrt(obj.gamma*obj.P/obj.rho);
            obj.u = obj.cv * obj.T; 
            obj.h = obj.cp * obj.T;
            obj.s = obj.R*(2.5+log(obj.mw/obj.rho/obj.NA*(4*pi/3/(obj.hplanck^2)*obj.u*(obj.mw/obj.NA)^2)^(1.5)));
            obj.mu = obj.mu_ref*sqrt(obj.T/obj.T_ref); % hard sphere model
            s = obj.state;
        end
        function s = update_PT(obj, P,T)
            obj.P = P;
            obj.T = T;
            s = obj.update();
        end
        function s =update_rhoP(obj,rho,P)
            obj.T = P/obj.R/rho;
            obj.P = P;
            s = obj.update();
        end
        function s = update_rhoT(obj,rho,T)
           obj.T = T;
           obj.P = rho*T*obj.R;
           s = obj.update();
        end
        function s = update_sT(~)
           error("This update method not supported."); 
        end
        function s = update_rhos(~)
           error("This update method not supported."); 
        end
        function s = update_uT(~)
           error("This update method not supported - state variables not independent."); 
        end
    end
end