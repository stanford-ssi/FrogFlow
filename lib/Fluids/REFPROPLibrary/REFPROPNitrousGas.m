classdef REFPROPNitrousGas < REFPROPNitrous& Gas
    methods
        function obj = REFPROPNitrousGas(override)
            if nargin < 3
                override = false;
            end
            obj@REFPROPNitrous('gas',override);
        end
    end
end