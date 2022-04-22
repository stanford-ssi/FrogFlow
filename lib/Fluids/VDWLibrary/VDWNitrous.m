classdef VDWNitrous < VDWFluid 
    properties(Constant,Hidden)
        Pr = DataHandle();
        Tr = DataHandle();
        rhor = DataHandle();
    end
    methods
        function obj = VDWNitrous(type)
            obj = obj@VDWFluid(9.358933919367716e+02,0.04401288,0.3832,0.00004415,type,1.47E-5,298.15);
        end
        function satcalc(obj)
            persistent Tr Pr rhor
            if isempty(Tr)
                [Tr, Pr, rhor] = obj.calcsatcurve();
            end
            obj.Tr.data = Tr;
            obj.Pr.data = Pr;
            obj.rhor.data = rhor;
        end
    end
end