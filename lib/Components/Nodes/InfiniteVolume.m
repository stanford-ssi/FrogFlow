classdef InfiniteVolume < Node
    properties(Access=protected)
        fluid;
        ode_state = [];
    end
    methods
        function obj = InfiniteVolume(fluid,P,T,update_order)
           if nargin < 4
                update_order = 0;
           end
           obj@Node(false,update_order);
           obj.fluid = fluid;
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
        function f = get_fluid(obj,~)
            f = obj.fluid;
        end
    end
end