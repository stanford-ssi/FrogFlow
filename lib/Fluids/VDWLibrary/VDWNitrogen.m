classdef VDWNitrogen < VDWFluid & Gas
    properties(Constant,Hidden)
        Pr = DataHandle();
        Tr = DataHandle();
        rhor = DataHandle();
    end
    methods
        function obj = VDWNitrogen(type)
            obj = obj@VDWFluid(743,.02802,0.137,0.0000387,type,1.76E-5,20+273.15);
        end
        function satcalc(obj)
            % Function specific to each type, uses persistent to avoid
            % re-calcing the saturation values on each sim run. Use    
            % <clear all> to force re-calc.
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