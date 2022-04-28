classdef EQTank < Tank
    properties(Access=private)
        dm_tol = 1E-3; 
    end
    % Equilbrium model for a self-pressurizing fluid.
    methods
        function obj = EQTank(ullage_fluid,liquid_fluid,Vtank,Vliq,Atank,update_order)
            if nargin < 6
                update_order = 0;
            end
           obj@Tank(TankUllage(ullage_fluid,Vtank-Vliq), TankLiquid(liquid_fluid,Vliq),Vtank,Atank,update_order);
           obj.ode_state = [obj.ullage_node.m + obj.liquid_node.m;  ...
               obj.ullage_node.m*obj.ullage_node.get_fluid().u + obj.liquid_node.m*obj.liquid_node.get_fluid().u];
        end
        function update(obj, ~, ode_state) 
            liq = obj.liquid_node.get_fluid();
            ull = obj.ullage_node.get_fluid();
            mtot = ode_state(1);
            Utot = ode_state(2);
            
            if obj.liquid_node.V <= 0
                Component.sim.set_flag('EQTank ran out of liquid.')
            end
            % iteratively determine T such that tank volume constraint is
            % satisfied.
%             if mtot > obj.V*ull.rho + obj.dm_tol % if liquid remaining (i.e. mass greater than mass of gas-filled tank)
                T = fzero(@(T) obj.V - findV(T), liq.T);
                liq.update_T(T);
                ull.update_T(T);
                x = (Utot/mtot - liq.u)/(ull.u - liq.u);
                obj.ullage_node.m = x*mtot;
                obj.liquid_node.m = (1-x)*mtot;
                obj.ullage_node.V = obj.ullage_node.m/ull.rho;
                obj.liquid_node.V = obj.liquid_node.m/liq.rho;
%             else % if only gas remaining, update based on density and energy
%                 disp('hey hey')
%                 ull.update_rhou(mtot/obj.V, Utot/(mtot)); % update ullage to check if empty
%                 obj.ullage_node.m = mtot;
%                 obj.liquid_node.m = 0;
%                 obj.ullage_node.V = obj.V;
%                 obj.liquid_node.V = 0;
%             end

            % Call update function to record & set children ode state
            obj.m = obj.ullage_node.m + obj.liquid_node.m;
            obj.U = obj.ullage_node.m*ull.u + obj.liquid_node.m*liq.u;
            obj.ode_state = ode_state;

            obj.ullage_node.update([],[obj.ullage_node.m; obj.ullage_node.m*ull.u]);
            obj.liquid_node.update([],[obj.liquid_node.m; obj.liquid_node.m*liq.u]);

            function V = findV(T)
                liq.update_T(T);
                ull.update_T(T);
                xvap = (Utot/mtot - liq.u)/(ull.u - liq.u);
                V = mtot*((1-xvap)/liq.rho + xvap/ull.rho);
            end
        end
        function ydot = odestatedot(obj)
            % override tank implementation, integrating total m and U
            ydot = odestatedot@Tank(obj);
            ydot = [ydot(1)+ydot(3); ydot(2)+ydot(4)]; % [m; U]
        end
    end
end