classdef VDWNitrogenGas < VDWNitrogen & Gas
    methods
        function obj = VDWNitrogenGas(P,T)
            if nargin < 1
                P = 1E5;
                T = 298;
            end
            obj = obj@VDWNitrogen('gas'); %1 = gas
            obj.update_PT(P,T);
        end
    end
end