classdef InfiniteVolume < Node
    methods
        function obj = InfiniteVolume(P,T)
           obj.state.P = P;
           obj.state.T = T;
        end
        function ydot = statedot(~)
           ydot = []; % no change, constant
        end
    end
end