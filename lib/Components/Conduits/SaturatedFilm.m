classdef SaturatedFilm < Node
    methods
        function obj = SaturatedFilm(fluid,T,A)
            if nargin == 0
                child_conduit = false;
           end
           obj@Node();
        end
    end
    methods(Abstract)
        [mdot, Udot] = flowdot(obj);
    end
end