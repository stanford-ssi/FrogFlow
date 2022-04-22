classdef Kerosene < IncompressibleLiquid
    methods
        function obj = Kerosene(P,T)
            if nargin == 0
                P = 1E5;
                T = 298.15;
            end
            obj@IncompressibleLiquid(780,0.170,2010,P,T,2*2.414E-5,247.8,140);
            obj.k = 0.145; % thermal conductivity override
        end
    end
end