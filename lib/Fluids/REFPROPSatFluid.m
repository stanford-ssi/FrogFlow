classdef REFPROPSatFluid < SatFluid
    properties(Abstract,Constant,Access=protected)
        % DataHandle used to contain NIST data
        sat_NIST;
    end    
    methods (Abstract)
        loadsatmat(obj,matfilename); % implement this in final non-abstract subclass to use persistent vars to avoid re-loading
        %         function loadsatmat(obj,matfilename)
        %             persistent satNISTdata 
        %             if isempty(satNISTdata)            
        %               satNISTdata = load(matfilename);
        %             end
        %             obj.sat_NIST.data = satNISTdata;
        %         end
    end
    properties (Access=private)
        % type - 'liquid' or 'vapor'/'gas'
        type;
    end   
    properties (Hidden)
        Tmin;
        Tmax;
    end
    methods
        function obj = REFPROPSatFluid(datafilename,type,override)
            if nargin < 3
                override = false;
            end
            obj@SatFluid();
            type = lower(type);
            if strcmpi(type,'gas')
                type = 'vapor';
            end
            obj.type = type;
            % If a mat file version of the datafile doesn't exist, 
            [fp,fn,~] = fileparts(datafilename);
            if isempty(fp)
                p = mfilename('fullpath');
                [fluidsloc,~,~] = fileparts(p);
                fp = fullfile(fluidsloc,'../../ref/NIST-REFPROP'); % check the library for this fluid type
            end
            if ~isfile([fullfile(fp,fn),'.mat']) || override
                obj.loadtxttosatmat([fullfile(fp,fn) '.txt']);
            end
            obj.loadsatmat([fullfile(fp,fn) '.mat']);
            obj.Tmin = obj.sat_NIST.data.T(1);
            obj.Tmax = obj.sat_NIST.data.T(end);
        end
        function update(obj,~)  
            T = obj.T;
            obj.rho = FastInterp1(obj.sat_NIST.data.T, obj.sat_NIST.data.(obj.type).rho, T); % J/kg
            obj.h = FastInterp1(obj.sat_NIST.data.T, obj.sat_NIST.data.(obj.type).h, T); % J/kg
            obj.u = FastInterp1(obj.sat_NIST.data.T, obj.sat_NIST.data.(obj.type).u, T); % J/kg
            obj.cv = FastInterp1(obj.sat_NIST.data.T, obj.sat_NIST.data.(obj.type).cv, T);
            obj.cp = FastInterp1(obj.sat_NIST.data.T, obj.sat_NIST.data.(obj.type).cp, T);
            obj.s = FastInterp1(obj.sat_NIST.data.T, obj.sat_NIST.data.(obj.type).s, T);
            obj.mw = FastInterp1(obj.sat_NIST.data.T, obj.sat_NIST.data.mw, T);
            obj.mu = FastInterp1(obj.sat_NIST.data.T, obj.sat_NIST.data.(obj.type).mu, T);
            obj.c = FastInterp1(obj.sat_NIST.data.T, obj.sat_NIST.data.(obj.type).c, T);
            obj.k = FastInterp1(obj.sat_NIST.data.T, obj.sat_NIST.data.(obj.type).k, T);
            obj.beta = FastInterp1(obj.sat_NIST.data.T, obj.sat_NIST.data.(obj.type).beta, T);
        end
        function update_T(obj,T)
            obj.T = T;
            obj.P = FastInterp1(obj.sat_NIST.data.T, obj.sat_NIST.data.P, T);
            obj.update(true);
        end
        function update_P(obj,P)
            obj.P = P;
            obj.T = interp1(obj.sat_NIST.data.P, obj.sat_NIST.data.T, P);
            obj.update(true);
        end
    end
    methods(Static)
        function dataout = loadtxttosatmat(txtfile)
            % Assumes headers are variable names, base SI units
            % (m/kg/Pa/J/etc)
            myopts = detectImportOptions(txtfile);
            myopts.DataLines = [6 Inf];
            myopts.VariableUnitsLine = 5;
            myopts.VariableDescriptionsLine = 3;
            myopts.VariableNamesLine = 4;
            data = readtable(txtfile,myopts); 
            dataout = struct('T',[]);
            varnames = data.Properties.VariableNames;
            fluidtype = data.Properties.VariableDescriptions;
            data = table2array(data);
            for i = 1:numel(varnames)
                thisvar = lower(regexprep(varnames{i}, '_+\d', ''));
                if thisvar(end) == '_'
                    thisvar = thisvar(1:end-1);
                end
                thistype = lower(fluidtype{i});
                switch thisvar
                    case 'pressure'
                        dataout.P = data(:,i);
                    case 'temperature'
                        dataout.T = data(:,i);
                    case 'heatofvapor'
                        dataout.hlv = data(:,i);
                    case 'int_energy'
                        dataout.(thistype).u = data(:,i);
                    case 'density'
                        dataout.(thistype).rho = data(:,i);
                    case 'enthalpy'
                        dataout.(thistype).h = data(:,i);
                    case 'entropy'
                        dataout.(thistype).s = data(:,i);
                    case 'cv'
                        dataout.(thistype).cv = data(:,i);
                    case 'cp'
                        dataout.(thistype).cp = data(:,i);
                    case 'soundspeed'
                        dataout.(thistype).c = data(:,i);
                    case 'comp_factor'
                        dataout.(thistype).z = data(:,i);
                    case 'therm_cond'
                        dataout.(thistype).k = data(:,i);
                    case 'viscosity'
                        dataout.(thistype).mu = data(:,i);
                    case 'vol_expansivity'
                        dataout.(thistype).beta = data(:,i);
                    case 'cp_cv'
                        dataout.(thistype).g = data(:,i);
                    case 'molarmass'
                        dataout.mw = data(:,i)./1000;
                end
            end
            [~,fn,~] = fileparts(txtfile);
            p = mfilename('fullpath');
            [fluidsloc,~,~] = fileparts(p);
            fp = fullfile(fluidsloc,'../../ref/NIST-REFPROP'); % add this fluid type to the library
            s = dataout;
            save([fullfile(fp,fn) '.mat'],'-struct',"s")
        end
    end
end