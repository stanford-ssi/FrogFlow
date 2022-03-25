classdef TankUllage < Node
    properties
        fluid;
        m;
        V; 
        tank_liquid = [];
        ode_state = [];
        update_order = 0;
    end
    methods
        function obj = TankUllage(fluid,V,P,T,update_order)
           obj@Node(true); % always a child component!
           obj.fluid = fluid;
           if nargin > 4
                obj.update_order = update_order;
           end
           if nargin > 2
                fluid.update_PT(P,T); % set fluid pressure/temp
           end
           obj.V = V;
           obj.m = obj.fluid.rho*V;
           obj.ode_state = [obj.m; obj.m*obj.fluid.u];
        end
        function update(obj, ~, ode_state)
            obj.ode_state = ode_state;
            obj.m = ode_state(1);
            obj.fluid.update_rhou(ode_state(1)/obj.V,ode_state(2)/ode_state(1));
            if obj.fluid.P == 0 || obj.fluid.T == 0
                Component.sim.set_flag("Tank Ullage pressure/temp went below zero.");
            end
        end
        function ydot = odestatedot(obj,inlet,outlet,Vdot)
           mdot = 0;
           Udot = 0;
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
           Udot = Udot - obj.fluid.P*Vdot; % add boundary work
           ydot = [mdot; Udot]; % mdot, udot
       end
        function s = state(obj)
            s = obj.fluid.state;
            s.m = obj.m;
            s.V = obj.V;
        end
        function f = get_fluid(obj, ~)
            f = obj.fluid;
        end
    end
end