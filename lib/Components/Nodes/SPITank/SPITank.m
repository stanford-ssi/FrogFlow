classdef SPITank < Tank
    % Simplest possible tank - incompressible liquid with an ullage gas
    properties(Hidden)
        PT_event = SimEvent(SimEvent.END,'SPITank:PTEvent','SPITank pressure or temp went below absolute zero.');
    end
    methods
        function obj = SPITank(ullage_fluid,liquid_fluid,Vtank,Vliq,Atank,update_order)
            if nargin < 6
                update_order = 0;
            end
           obj@Tank(TankUllage(ullage_fluid,Vtank-Vliq), TankLiquid(liquid_fluid,Vliq),Vtank,Atank,update_order);
        end
        function update(obj, t, ode_state)
            liq = obj.liquid_node.get_fluid();
            ull = obj.ullage_node.get_fluid();
            ode_ullage = ode_state(1:2); % ullage ode
            ode_liquid = ode_state(3:4); % liquid ode
           
            % Update liquid mass, calc volume from known density
            obj.liquid_node.m = max(ode_liquid(1),0); % Ensure liquid mass doesn't go negative
            if obj.liquid_node.m < 1E-3
                obj.liquid_node.m = 0;
            end
            obj.liquid_node.V = obj.liquid_node.m/liq.rho; % Update liquid volume
            
            % Update ullage volume, mass, then update ullage fluid
            obj.ullage_node.V = obj.V - obj.liquid_node.V;
            obj.ullage_node.m = ode_ullage(1);
            ull.update_rhou(ode_ullage(1)/obj.ullage_node.V,ode_ullage(2)/ode_ullage(1));

            % Ensure gas pressure/temp > zero
            if ull.P <= 0 || ull.T <= 0
                obj.PT_event.trigger(t);
            end
            
            % Update liquid fluid
            if obj.liquid_node.m > 1E-6
                liq.update_uP(ode_liquid(2)/ode_liquid(1),ull.P);
            else % if mass is near zero, use previous value
                liq.update_uP(liq.u,ull.P);
            end

            % Update overall mass, energy
            obj.m = obj.ullage_node.m + obj.liquid_node.m;
            obj.U = obj.ullage_node.m*ull.u + obj.liquid_node.m*liq.u;
            
            % Call update function to set children ode state
            update@Tank(obj,[],ode_state); % update ode_states
        end
    end
end