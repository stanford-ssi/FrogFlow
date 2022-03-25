classdef TankLiquid < Node
    properties
        fluid;
        m;
        u;
        V; 
        P;
        ode_state = [];
        update_order = 0;
    end
    methods
        function obj = TankLiquid(fluid,V,P,T,update_order)
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
           obj.u = obj.fluid.u;
           obj.ode_state = [obj.m; obj.m*obj.fluid.u];
        end
        function update(obj, ~, ode_state)
            obj.ode_state = ode_state;
            obj.m = max(ode_state(1),0);
            if obj.m < 1E-6
                obj.m = 0;
            end
            obj.V = obj.m/obj.fluid.rho;
            if obj.m > 0
                obj.u = ode_state(2)/obj.m;
            end
        end
        function update_fluid(obj,P)
            obj.P = P;
            obj.fluid.update_uP(obj.u,P);
        end
        function s = state(obj)
            s = obj.fluid.state;
            s.m = obj.m;
            s.V = obj.V;
        end
        function ydot = odestatedot(obj,inlet,outlet)
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
           Udot = Udot - obj.P/obj.fluid.rho*mdot; % add boundary work from changing volume
           ydot = [mdot; Udot]; % mdot, udot
       end
        function f = get_fluid(obj, height)
            if isprop(Component.sim,'accel')
                a = Component.sim.accel;
            else
                a = 9.8066;
            end
            f = obj.fluid;
            f.update_uP(obj.u,obj.P+obj.fluid.rho*a*height); % adjust pressure for hydrostatic head
        end
    end
end