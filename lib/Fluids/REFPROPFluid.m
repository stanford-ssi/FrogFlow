classdef REFPROPFluid < Fluid
    properties(Abstract, Constant,Access=protected)
        % struct used to contain NIST data
        NIST;
    end
    properties(Access=private)
        type;
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
        function obj = REFPROPFluid(datafilename,type,override)
            if nargin < 3
                override = false;
            end
            obj@Fluid();
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
                obj.loadtxttomat([fullfile(fp,fn) '.txt']);
            end
            obj.loadmat([fullfile(fp,fn) '.mat']);
        end
        function update(obj,~)  
            % use P and T to do fast interpolation based on fixed step grid size
            T = obj.T;
            P = obj.P; 
            obj.rho = obj.NIST.data.(obj.type).FPT.rho(P,T); 
            obj.h = obj.NIST.data.(obj.type).FPT.h(P,T);
            obj.u = obj.NIST.data.(obj.type).FPT.u(P,T); 
            obj.cv = obj.NIST.data.(obj.type).FPT.cv(P,T); 
            obj.cp = obj.NIST.data.(obj.type).FPT.cp(P,T); 
            obj.s = obj.NIST.data.(obj.type).FPT.s(P,T); 
            obj.mw = obj.NIST.data.FPT.mw(P,T); 
            obj.mu = obj.NIST.data.(obj.type).FPT.mu(P,T); 
            obj.c = obj.NIST.data.(obj.type).FPT.c(P,T); 
            obj.k = obj.NIST.data.(obj.type).FPT.k(P,T); 
            obj.beta = obj.NIST.data.(obj.type).FPT.beta(P,T); 
        end

        function update_PT(obj,P,T)
            obj.P = P;
            obj.T = T;
            obj.update();
        end
        function update_rhoP(obj,rho,P)
            obj.P = P;
            obj.T = griddata(obj.NIST.data.(obj.type).rho,obj.NIST.data.P,obj.NIST.data.T,rho,P);
            obj.update();
        end
        function update_rhoT(obj,rho,T)
            obj.T = T;
            obj.P = obj.NIST.data.(obj.type).FrhoT.P(rho,T);
            obj.update();
        end
        function update_rhoh(obj,rho,h)
            obj.T = griddata(obj.NIST.data.(obj.type).rho,obj.NIST.data.(obj.type).h,obj.NIST.data.T,rho,h);
            obj.P = griddata(obj.NIST.data.(obj.type).rho,obj.NIST.data.(obj.type).h,obj.NIST.data.P,rho,h);
        end
        function update_rhos(obj,rho,s)
            obj.T = griddata(obj.NIST.data.(obj.type).rho,obj.NIST.data.(obj.type).s,obj.NIST.data.T,rho,s);
            obj.P = griddata(obj.NIST.data.(obj.type).rho,obj.NIST.data.(obj.type).s,obj.NIST.data.P,rho,s);
        end
        function update_rhou(obj,rho,u)
            obj.T = obj.NIST.data.(obj.type).Frhou.T(rho,u);
            obj.P = obj.NIST.data.(obj.type).Frhou.P(rho,u);
            obj.update();
        end
        function update_sT(obj,s,T)
            obj.T = T;
            obj.P = griddata(obj.NIST.data.(obj.type).s,obj.NIST.data.T,obj.NIST.data.P,s,T);
        end
        function update_uT(obj,u,T)
            obj.T = T;
            obj.P = griddata(obj.NIST.data.(obj.type).u,obj.NIST.data.T,obj.NIST.data.P,u,T);
        end
        function update_uP(obj,u,P)
            obj.P = P;
            obj.T = griddata(obj.NIST.data.(obj.type).u,obj.NIST.data.P,obj.NIST.data.T,u,P);
        end
        function update_hT(obj,h,T)
            obj.T = T;
            obj.P = griddata(obj.NIST.data.(obj.type).h,obj.NIST.data.T,obj.NIST.data.P,h,T);
        end
        function update_hP(obj,h,P)
            obj.P = P;
            obj.T = griddata(obj.NIST.data.(obj.type).h,obj.NIST.data.P,obj.NIST.data.T,h,P);
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
            myopts.VariableUnitsLine = 5;
            myopts.VariableDescriptionsLine = 3;
            myopts.VariableNamesLine = 4;
            myopts.Whitespace = '\b\t SupercooledSubcooledUndefined';
            myopts = setvaropts(myopts,'Type','double','FillValue',NaN);
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
                    case 'molarmass'
                        dataout.mw = data(:,i)./1000;
                end
                if isempty(thistype)
                    continue
                end
                switch thisvar
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
                end
            end

            nonnan = ~isnan(dataout.mw);
            dataout.('FPT').mw = scatteredInterpolant(dataout.P(nonnan),dataout.T(nonnan),dataout.mw(nonnan));
            types = {'liquid','vapor'};
            for j = 1:numel(types)
                thistype = types{j};
                datafields = fieldnames(dataout.(thistype));
                for i = 1:numel(datafields)
                    nonnan = ~isnan(dataout.(thistype).(datafields{i}));
                    dataout.(thistype).('FPT').(datafields{i}) = scatteredInterpolant(dataout.P(nonnan),dataout.T(nonnan),dataout.(thistype).(datafields{i})(nonnan),'natural');
                end
                nonnan = ~isnan(dataout.(thistype).rho) & ~isnan(dataout.(thistype).u);
                dataout.(thistype).('Frhou').P = scatteredInterpolant(dataout.(thistype).rho(nonnan),dataout.(thistype).u(nonnan),dataout.P(nonnan),'natural');
                dataout.(thistype).('Frhou').T = scatteredInterpolant(dataout.(thistype).rho(nonnan),dataout.(thistype).u(nonnan),dataout.T(nonnan),'natural');
                dataout.(thistype).('FrhoT').P = scatteredInterpolant(dataout.(thistype).rho(nonnan),dataout.T(nonnan),dataout.P(nonnan),'natural');
            end
            [~,fn,~] = fileparts(txtfile);
            p = mfilename('fullpath');
            [fluidsloc,~,~] = fileparts(p);
            fp = fullfile(fluidsloc,'../../ref/NIST-REFPROP'); % add this fluid type to the library
            s = dataout;
            save([fullfile(fp,fn) '.mat'],'-struct',"s");
        end
    end
end