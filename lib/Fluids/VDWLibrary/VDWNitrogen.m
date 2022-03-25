classdef VDWNitrogen < VDWGas
    methods
        function obj = VDWNitrogen(P,T)
            if nargin < 1
                P = 1E5;
                T = 298;
            end
            obj = obj@VDWGas(743,.02802,0.137,0.0000387,1.76E-5,20+273.15);
            obj.update_PT(P,T);
        end
    end
end