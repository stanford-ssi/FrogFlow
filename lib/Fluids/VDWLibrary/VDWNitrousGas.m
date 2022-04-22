classdef VDWNitrousGas < VDWNitrous & Gas
    methods
        function obj = VDWNitrousGas(P,T)
            if nargin < 1
                P = 1E5;
                T = 298;
            end
            obj = obj@VDWNitrous('gas'); % 1 = gas
            obj.update_PT(P,T);
        end
    end
end