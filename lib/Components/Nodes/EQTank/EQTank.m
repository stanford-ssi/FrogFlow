classdef EQTank < Tank
    properties(Access=private)
        dm_tol = 1E-3; 
    end
    properties(Hidden)
        liq_runout_event = SimEvent(SimEvent.CONTINUE,'EQTank:LiquidRunout','EQTank liquid ran out, starting gas blowdown.');
        blowdown_end_event = SimEvent(SimEvent.END,'EQTank:BlowdownTerminated','EQTank finished blowdown.');
    end
    % Equilbrium model for a self-pressurizing fluid.
    methods
        function obj = EQTank(ullage_fluid,liquid_fluid,Vtank,Vliq,Atank,update_order)
            if nargin < 6
                update_order = 0;
            end
           obj@Tank(TankUllage(ullage_fluid,Vtank-Vliq), TankLiquid(liquid_fluid,Vliq),Vtank,Atank,update_order);
        end
        function update(obj, t, ode_state) 
            liq = obj.liquid_node.get_fluid();
            ull = obj.ullage_node.get_fluid();
            mtot = ode_state(1)+ode_state(3);
            Utot = ode_state(2)+ode_state(4);
            % iteratively determine T such that tank volume constraint is
            % satisfied.
            if ~obj.liq_runout_event.occurred(t) % if liquid mass remaining 
                T = fzero(@(T) obj.V - findV(T), liq.T);
                liq.update_T(T);
                ull.update_T(T);
                x = (Utot/mtot - liq.u)/(ull.u-liq.u); % boil, conserving internal inergy
                obj.ullage_node.m = x*mtot;
                obj.liquid_node.m = (1-x)*mtot;
                m = obj.liquid_node.m;
                if abs(m) < 1E-6
                    obj.liq_runout_event.trigger(t);
                end
                obj.ullage_node.V = obj.ullage_node.m/ull.rho;
                obj.liquid_node.V = obj.liquid_node.m/liq.rho;
            else  % if only gas remaining, update based on density and energy
%                 ull.update_rhou(ode_state(1)/obj.V, ode_state(2)/ode_state(1)); % update ullage to check if empty
%                 obj.ullage_node.m = ode_state(1);
%                 obj.liquid_node.m = 0;
%                 obj.ullage_node.V = obj.V;
%                 obj.liquid_node.V = 0;
%             end
                obj.blowdown_end_event.trigger();
            end
            % Call update function to record & set children ode state
            obj.m = obj.ullage_node.m + obj.liquid_node.m;
            obj.U = obj.ullage_node.m*ull.u + obj.liquid_node.m*liq.u;
            obj.ode_state = [obj.ullage_node.m; obj.ullage_node.m*ull.u; obj.liquid_node.m; obj.liquid_node.m*liq.u];

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
            if ydot(1) > 0 || ydot(3) > 0 % if flow reverses into the tank, blowdown is over
                obj.blowdown_end_event.trigger();
            end
        end
    end
end