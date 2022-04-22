classdef TankUllage < Node
    properties(Access=protected)
        fluid;
        tank_parent;
        ode_state = [];
    end
    properties
        m;
        V; 
    end
    methods
        function obj = TankUllage(fluid,V,update_order)
           if nargin < 3
                update_order = 0;
           end
           obj@Node(true,update_order); % always a child component!
           obj.fluid = fluid;
           obj.V = V;
           obj.m = obj.fluid.rho*V;
           obj.ode_state = [obj.m; obj.m*obj.fluid.u];
        end
        function update(obj, ~, ode_state)
            obj.ode_state = ode_state;
            if obj.fluid.P <= 0 || obj.fluid.T <= 0
                Component.sim.set_flag("Tank Ullage pressure/temp went below zero.");
            end
        end
        function ydot = odestatedot(obj,inlet,outlet,dVdt)
           % first, collect flow from intra-tank components
           ydot = odestatedot@Node(obj);
           mdot = ydot(1);
           Udot = ydot(2);
           % iterate through inlets, add mdot and udot
           for k = 1:numel(inlet)
                [md, ud] = inlet{k}.flowdot();
                mdot = mdot + md;
                Udot = Udot + ud;
           end
           % iterate through outlets, subtract mdot and udot
           for k = 1:numel(outlet)
                [md, ud] = outlet{k}.flowdot();
                mdot = mdot - md;
                Udot = Udot - ud;
           end
           Udot = Udot - obj.fluid.P*dVdt; % add boundary work
           ydot = [mdot; Udot]; % mdot, udot
        end
        function f = get_fluid(obj, ~)
            f = obj.fluid;
        end
        function set_tank_parent(obj,tank_parent)
            obj.tank_parent = tank_parent;
        end
    end
end