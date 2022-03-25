classdef Water < IncompressibleLiquid
    methods
        function obj = Water(P,T)
            if nargin == 0
                P = 1E5;
                T = 298.15;
            end
            obj@IncompressibleLiquid(1000,0.018015,4184,P,T,2.414E-5,247.8,140);
        end
    end
end