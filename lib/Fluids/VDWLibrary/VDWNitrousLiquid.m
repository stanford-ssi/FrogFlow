classdef VDWNitrousLiquid < VDWNitrous 
    methods
        function obj = VDWNitrousLiquid(P,T)
            if nargin < 1
                P = 1E5;
                T = 298;
            end
            obj = obj@VDWNitrous('liquid'); 
            obj.update_PT(P,T);
        end
    end
end