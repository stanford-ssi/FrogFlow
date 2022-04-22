classdef IncompressibleLiquid  < Fluid
    % incompressible fluid with constant specific heat
    properties(Access=protected)
       A = 1;
       B = 1; 
       C = 1; % A/B/C used to calculate dynamic viscosity as A*10^(B/(T-C))
    end
    methods
        function obj = IncompressibleLiquid(rho,mw,c,P,T,A,B,C)
            obj.rho = rho;
            obj.mw = mw;
            obj.cv = c;
            obj.cp = c;
            obj.P = P;
            obj.T = T;
            obj.A = A;
            obj.B = B;
            obj.C = C;
            obj.c = Inf;
            obj.k = 0.609; % thermal conductivity, W/m/K
            obj.beta = 0; % coefficient of thermal expansion, =0 for incompressible
            obj.update();
        end
        % STATE UPDATING --------------------------------------------------
        function update(obj)
            obj.u = obj.cv*obj.T;
            obj.h = obj.u + obj.P/obj.rho; 
            obj.s = obj.cv*log(obj.T);
            obj.mu = obj.A*10^(obj.B/(obj.T-obj.C));
        end
        function update_PT(obj,P,T)
            obj.P = P;
            obj.T = T;
            obj.update();
        end
        function update_hP(obj,h,P)
            obj.P = P;
            obj.T = (h - P/obj.rho)/obj.cv;
            obj.update();
        end
        function update_uP(obj,u,P)
            obj.P = P;
            obj.T = u/obj.cv;
            obj.update();
        end
        function update_rhoP(~)
            error("This update method not supported - state variables not independent."); 
        end
        function update_rhoT(~)
            error("This update method not supported - state variables not independent."); 
        end
        function update_rhoh(~)
            error("This update method not supported - state variables not independent."); 
        end
        function update_rhos(~)
            error("This update method not supported - state variables not independent."); 
        end
        function update_rhou(~)
            error("This update method not supported - state variables not independent."); 
        end
        function update_sT(~)
            error("This update method not supported - state variables not independent."); 
        end
        function update_uT(~)
            error("This update method not supported - state variables not independent."); 
        end
        function update_hT(~)
            error("This update method not supported - state variables not independent."); 
        end
        % STATE DERIVATIVES -----------------------------------------------
        function dpdt = dPdT(~)
            dpdt = 0;
        end
        function dpdrho = dPdrho(~)
            dpdrho = 0;
        end
        function dudrh = dudrho(~)
            dudrh = 0;
        end
        function dudt = dudT(obj)
            dudt = obj.cv;
        end
    end
end