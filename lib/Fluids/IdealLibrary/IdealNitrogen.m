classdef IdealNitrogen < IdealGas
    methods
        function obj = IdealNitrogen(P,T)
            if nargin < 1
                P = 1E5;
                T = 298;
            end
            obj = obj@IdealGas(1.4,2*14.0067/1000,P,T,1.76E-5,20+273.15);
        end
    end
end