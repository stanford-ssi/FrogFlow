classdef (Abstract) SatFluid < Fluid
    methods(Abstract)
        update_T(obj,T);
        update_P(obj,P);
    end
    properties(Abstract, Hidden)
        Tmin;
        Tmax;
    end
end