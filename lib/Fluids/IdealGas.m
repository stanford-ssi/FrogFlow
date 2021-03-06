classdef IdealGas < Gas
    properties(Access=protected)
       mu_ref = 1E-5; % dynamic viscosity @ T_ref, Pa*s 
       T_ref = 273.15; % reference temp for dynamic viscosity, K
    end
    methods
        function obj = IdealGas(gamma,mw,P,T,mu_ref,T_ref)
            obj = obj@Gas();
            obj.mw = mw;
            obj.cv = obj.R/(gamma-1);
            obj.cp = obj.cv + obj.R;
            obj.P = P;
            obj.T = T;
            if nargin > 4
                obj.mu_ref = mu_ref;
            end
            if nargin > 5
                obj.T_ref = T_ref;
            end
            obj.k = 0.02; % thermal conductivity, W/m/K, roughly 0.02 for ideal gases near room temp
            obj.beta = 1; % coefficient of thermal expansion, 1/K
            obj.update();
        end
        % STATE UPDATING -----------------------------------------
        function update(obj)
            if obj.P < 0
                obj.P = 0;
            end
            if obj.T < 0
                obj.T = 0;
            end
            obj.rho = obj.P/obj.R/obj.T; % ideal gas law
            obj.c = sqrt(obj.gamma*obj.P/obj.rho);
            obj.u = obj.cv * obj.T; 
            obj.h = obj.cp * obj.T;
            obj.s = obj.R*(2.5+log(obj.mw/obj.rho/obj.NA*(4*pi/3/(obj.hplanck^2)*obj.u*(obj.mw/obj.NA)^2)^(1.5)));
            obj.mu = obj.mu_ref*sqrt(obj.T/obj.T_ref); % hard sphere model
            obj.beta = 1/obj.T;
        end
        function update_PT(obj, P,T)
            obj.P = P;
            obj.T = T;
            obj.update();
        end
        function update_rhoP(obj,rho,P)
            obj.T = P/obj.R/rho;
            obj.P = P;
            obj.update();
        end
        function update_rhoT(obj,rho,T)
           obj.T = T;
           obj.P = rho*T*obj.R;
           obj.update();
        end
        function update_rhoh(obj,rho,h)
           obj.T = h/obj.cp;
           obj.P = rho*obj.R*obj.T;
           obj.update();
        end
        function update_rhou(obj,rho,u)
            obj.T = u/obj.cv;
            obj.P = rho*obj.R*obj.T;
            obj.update();
        end
        function update_uP(obj,u,P)
           obj.P = P;
           obj.T = u/obj.cv;
           obj.update()
        end
        function update_rhos(~)
           error("This update method not supported."); 
        end
        function update_sT(~)
           error("This update method not supported."); 
        end
        function update_uT(~)
           error("This update method not supported - state variables not independent."); 
        end
        function update_hT(~)
           error("This update method not supported - state variables not independent."); 
        end
        function update_hP(obj,h,P)
           obj.T = h/obj.cp;
           obj.P = P;
           obj.update();
        end
        % STATE DERIVATIVES -----------------------------------------------
        function dpdt = dPdT(obj)
            dpdt = obj.R*obj.rho;
        end
        function dpdrho = dPdrho(obj)
            dpdrho = obj.R*obj.T;
        end
        function dudrh = dudrho(obj)
            dudrh = -obj.cv*obj.P/(obj.rho^2)/obj.R;
        end
        function dudt = dudT(obj)
            dudt = obj.cv;
        end
    end
end