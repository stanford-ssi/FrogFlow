classdef REFPROPFluid < Fluid
    properties(Abstract, Constant,Access=protected)
        % struct used to contain NIST data
        NIST;
    end
    methods (Abstract)
        loadmat(obj,matfilename); % implement this in final non-abstract subclass to use persistent vars to avoid re-loading
        %         function loadmat(obj,matfilename)
        %             persistent NISTdata 
        %             if isempty(NISTdata)            
        %               NISTdata = load(matfilename);
        %             end
        %             obj.NIST.data = NISTdata;
        %         end
    end
    methods
        function obj = REFPROPFluid(datafilename,override)
            if nargin < 2
                override = false;
            end
            obj@Fluid();
            % If a mat file version of the datafile doesn't exist, 
            [fp,fn,~] = fileparts(datafilename);
            if isempty(fp)
                p = mfilename('fullpath');
                [fluidsloc,~,~] = fileparts(p);
                fp = fullfile(fluidsloc,'../../ref/NIST-REFPROP'); % check the library for this fluid type
            end
            if ~isfile([fullfile(fp,fn),'.mat']) || override
                obj.loadtxttomat([fullfile(fp,fn) '.txt']);
            end
            obj.loadmat([fullfile(fp,fn) '.mat']);
        end
        function update(obj,~)  
            % use P and T to do fast interpolation based on fixed step grid size
            T = obj.T;
            P = obj.P; 
            obj.rho = FastInterp2(obj.NIST.data.P, obj.NIST.data.T, obj.NIST.data.rho, P,T); % J/kg
            obj.h = FastInterp2(obj.NIST.data.P,obj.NIST.data.T, obj.NIST.data.h, P,T); % J/kg
            obj.u = FastInterp2(obj.NIST.data.P,obj.NIST.data.T, obj.NIST.data.u, P,T); % J/kg
            obj.cv = FastInterp2(obj.NIST.data.P,obj.NIST.data.T, obj.NIST.data.cv, P,T);
            obj.cp = FastInterp2(obj.NIST.data.P,obj.NIST.data.T, obj.NIST.data.cp, P,T);
            obj.s = FastInterp2(obj.NIST.data.P,obj.NIST.data.T, obj.NIST.data.s, P,T);
            obj.mw = FastInterp2(obj.NIST.data.P,obj.NIST.data.T, obj.NIST.data.mw, P,T);
            obj.mu = FastInterp2(obj.NIST.data.P,obj.NIST.data.T, obj.NIST.data.mu, P,T);
            obj.c = FastInterp2(obj.NIST.data.P,obj.NIST.data.T, obj.NIST.data.c, P,T);
            obj.k = FastInterp2(obj.NIST.data.P,obj.NIST.data.T, obj.NIST.data.k, P,T);
            obj.beta = FastInterp2(obj.NIST.data.P,obj.NIST.data.T, obj.NIST.data.beta, P,T);
        end

        function update_PT(obj,P,T)
            obj.P = P;
            obj.T = T;
            obj.update();
        end
        function update_rhoP(obj,rho,P)
            obj.P = P;
            obj.T = griddata(obj.NIST.data.rho,obj.NIST.data.P,obj.NIST.data.T,rho,P);
            obj.update();
        end
        function update_rhoT(obj,rho,T)
            persistent FPofrho
            if isempty(FPofrho)
                FPofrho = scatteredInterpolant(reshape(obj.NIST.data.rho,[],1),reshape(obj.NIST.data.T,[],1),reshape(obj.NIST.data.P,[],1));
            end
            obj.T = T;
            obj.P = FPofrho(rho,T);
            obj.update();
        end
        function update_rhoh(obj,rho,h)
            obj.T = griddata(obj.NIST.data.rho,obj.NIST.data.h,obj.NIST.data.T,rho,h);
            obj.P = griddata(obj.NIST.data.rho,obj.NIST.data.h,obj.NIST.data.P,rho,h);
        end
        function update_rhos(obj,rho,s)
            obj.T = griddata(obj.NIST.data.rho,obj.NIST.data.s,obj.NIST.data.T,rho,s);
            obj.P = griddata(obj.NIST.data.rho,obj.NIST.data.s,obj.NIST.data.P,rho,s);
        end
        function update_rhou(obj,rho,u)
            persistent FT FP
            if isempty(FT)
                FT = scatteredInterpolant(reshape(obj.NIST.data.rho,[],1),reshape(obj.NIST.data.u,[],1),reshape(obj.NIST.data.T,[],1));
                FP = scatteredInterpolant(reshape(obj.NIST.data.rho,[],1),reshape(obj.NIST.data.u,[],1),reshape(obj.NIST.data.P,[],1));
            end % this is way faster, but need to fix it so we can handle multiple fluids... could live in NIST.data?
            obj.T = FT(rho,u);
            obj.P = FP(rho,u);
        end
        function update_sT(obj,s,T)
            obj.T = T;
            obj.P = griddata(obj.NIST.data.s,obj.NIST.data.T,obj.NIST.data.P,s,T);
        end
        function update_uT(obj,u,T)
            obj.T = T;
            obj.P = griddata(obj.NIST.data.u,obj.NIST.data.T,obj.NIST.data.P,u,T);
        end
        function update_uP(obj,u,P)
            obj.P = P;
            obj.T = griddata(obj.NIST.data.u,obj.NIST.data.P,obj.NIST.data.T,u,P);
        end
        function update_hT(obj,h,T)
            obj.T = T;
            obj.P = griddata(obj.NIST.data.h,obj.NIST.data.T,obj.NIST.data.P,h,T);
        end
        function update_hP(obj,h,P)
            obj.P = P;
            obj.T = griddata(obj.NIST.data.h,obj.NIST.data.P,obj.NIST.data.T,h,P);
        end

        function dPdT(~); error("Not implemented for this fluid"); end
        function dPdrho(~); error("Not implemented for this fluid"); end
        function dudrho(~); error("Not implemented for this fluid"); end
    end
    methods(Static)
        function dataout = loadtxttomat(txtfile)
            % Assumes headers are variable names, base SI units
            % (m/kg/Pa/J/etc)
            myopts = detectImportOptions(txtfile,'Whitespace','\b\t SupercooledSubcooledUndefined');
            myopts.DataLines = [6 Inf];
            myopts.VariableUnitsLine = 4;
            myopts.VariableDescriptionsLine = 3;
            myopts.VariableNamesLine = 3;
            myopts.Whitespace = '\b\t SupercooledSubcooledUndefined';
            myopts = setvaropts(myopts,'Type','double','FillValue',NaN);
            data = readtable(txtfile,myopts); 
            dataout = struct('T',[]);
            varnames = data.Properties.VariableNames;
            data = table2array(data);
            for i = 1:numel(varnames)
                thisvar = lower(regexprep(varnames{i}, '_+\d', ''));
                if thisvar(end) == '_'
                    thisvar = thisvar(1:end-1);
                end
                switch thisvar
                    case 'pressure'
                        dataout.P = data(:,i);
                    case 'temperature'
                        dataout.T = data(:,i);
                    case 'int_energy'
                        dataout.u = data(:,i);
                    case 'density'
                        dataout.rho = data(:,i);
                    case 'enthalpy'
                        dataout.h = data(:,i);
                    case 'entropy'
                        dataout.s = data(:,i);
                    case 'cv'
                        dataout.cv = data(:,i);
                    case 'cp'
                        dataout.cp = data(:,i);
                    case 'soundspeed'
                        dataout.c = data(:,i);
                    case 'comp_factor'
                        dataout.z = data(:,i);
                    case 'therm_cond'
                        dataout.k = data(:,i);
                    case 'viscosity'
                        dataout.mu = data(:,i);
                    case 'vol_expansivity'
                        dataout.beta = data(:,i);
                    case 'cp_cv'
                        dataout.g = data(:,i);
                    case 'molarmass'
                        dataout.mw = data(:,i)./1000;
                end
            end
            collength = find(dataout.T-dataout.T(1),1) - 1;
            dataout.T = reshape(dataout.T,collength,[]).';
            dataout.P = reshape(dataout.P,collength,[]).';
            k = 4; % increase grid resolution by factor
            newT = linspace(dataout.T(1,1),dataout.T(end,1),(length(dataout.T(:,1))-1)*k+1); % improve resolution by 4
            newP = linspace(dataout.P(1,1),dataout.P(1,end),(length(dataout.P(1,:))-1)*k+1); % improve resolution by 4
            [newP, newT] = meshgrid(newP, newT);
            datafields = fieldnames(dataout);
            for i = 1:numel(datafields)
                if ~strcmpi(datafields{i},'P') && ~strcmpi(datafields{i},'T')
                    dataout.(datafields{i}) = reshape(dataout.(datafields{i}),collength,[]).';
                    dataout.(datafields{i}) = interp2(dataout.P,dataout.T,dataout.(datafields{i}),newP,newT,'linear');
                end
            end
            dataout.T = newT;
            dataout.P = newP;
            [~,fn,~] = fileparts(txtfile);
            p = mfilename('fullpath');
            [fluidsloc,~,~] = fileparts(p);
            fp = fullfile(fluidsloc,'../../ref/NIST-REFPROP'); % add this fluid type to the library
            s = dataout;
            save([fullfile(fp,fn) '.mat'],'-struct',"s");
        end
    end
end