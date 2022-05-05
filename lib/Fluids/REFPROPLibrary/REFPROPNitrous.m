classdef REFPROPNitrous < REFPROPFluid & REFPROPSatFluid
    properties(Constant,Access=protected)
        NIST = DataHandle();
        sat_NIST = DataHandle();
    end
    methods
        function obj = REFPROPNitrous(type,override)
            if nargin < 2
                override = false;
            end
            obj@REFPROPFluid('REFPROP_Nitrous_data.txt',type,override);
            obj@REFPROPSatFluid('REFPROP_SatNitrous_data.txt',type,override);
        end
        function loadmat(obj,matfilename)
            persistent NISTdata 
            if isempty(NISTdata)            
              NISTdata = load(matfilename);
            end
            obj.NIST.data = NISTdata;
        end
        function loadsatmat(obj,matfilename)
            persistent satNISTdata 
            if isempty(satNISTdata)            
              satNISTdata = load(matfilename);
            end
            obj.sat_NIST.data = satNISTdata;
        end
        function update(obj,~)
            if nargin > 1
                update@REFPROPSatFluid(obj);
            else
                update@REFPROPFluid(obj);
            end
        end
    end
end