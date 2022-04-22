classdef REFPROPNitrousLiquid < REFPROPNitrous & Liquid
    methods
        function obj = REFPROPNitrousLiquid(override)
            if nargin < 1
                override = false;
            end
            obj@REFPROPNitrous('liquid',override);
        end
    end
end