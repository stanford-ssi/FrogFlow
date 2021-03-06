classdef GasPlenum < Node
    properties
        m;
        V;
    end
    properties(Access=protected)
        fluid;
        ode_state = [];
        PT_event = SimEvent(SimEvent.END,'SPITank:PTEvent','SPITank pressure or temp went below absolute zero.');
    end
    methods
        function obj = GasPlenum(fluid,V,P,T,update_order)
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
        function update(obj, t, ode_state)
            obj.ode_state = ode_state;
            obj.m = ode_state(1);
            obj.fluid.update_rhou(ode_state(1)/obj.V,ode_state(2)/ode_state(1));
            if obj.fluid.P <= 0 || obj.fluid.T <= 0
                obj.PT_event.trigger(t); %trigger simulation end
            end
        end
        function f = get_fluid(obj, ~)
            f = obj.fluid;
        end
    end
end