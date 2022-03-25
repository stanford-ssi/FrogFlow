classdef InfiniteVolume < Node
    properties
        fluid;
        ode_state = [];
        update_order = 0;
    end
    methods
        function obj = InfiniteVolume(fluid,P,T,update_order)
           obj.fluid = fluid;
           if nargin > 3
                obj.update_order = update_order;
           end
           if nargin > 1
                fluid.update_PT(P,T); % set fluid pressure/temp
           end
        end
        function update(~)
            return;
        end
        function ydot = odestatedot(~)
           ydot = []; % no change, constant
        end
        function s = state(obj)
            s = obj.fluid.state;
        end
        function f = get_fluid(obj,~)
            f = obj.fluid;
        end
    end
end