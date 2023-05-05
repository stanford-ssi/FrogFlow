classdef TankLiquid < Node
    properties
        m;
        V; 
    end
    properties(Access=protected)
        fluid;
        u;
        P;
        tank_parent;
        tank_liquid = [];
        ode_state = [];
    end
    methods
        function obj = TankLiquid(fluid,V,update_order)
           if nargin < 3
                update_order = 0;
           end
           obj@Node(true,update_order); % always a child component!
           obj.fluid = fluid;
           obj.V = V;
           obj.m = obj.fluid.rho*V;
           obj.ode_state = [obj.m; obj.m*obj.fluid.u];
        end
        function m = extract(obj)
            m = obj.m;
%             obj.ode_state = [obj.m; obj.m*obj.fluid.u];
        end
        function update(obj, ~, ode_state)
            obj.m = ode_state(1);
            obj.ode_state = ode_state;
        end
        function ydot = odestatedot(obj,inlet,outlet)
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
           Udot = Udot - obj.fluid.P*mdot/obj.fluid.rho; % add boundary work
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