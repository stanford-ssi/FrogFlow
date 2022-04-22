classdef IdealNitrous < IdealGas
    methods
        function obj = IdealNitrous(P,T)
            if nargin < 1
                P = 1E5;
                T = 298;
            end
            obj = obj@IdealGas(1.2019,0.04401288,P,T);
        end
    end
end