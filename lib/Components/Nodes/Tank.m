classdef Tank < Node
    properties
        fluid = [];
        tank_ullage;
        tank_liquid;
        m;
        Vtank; 
        Atank;
        ode_state = [];
        update_order = 0;
    end
    methods
        function obj = Tank(ullage_fluid,liquid_fluid,Vtank,Vliq,Atank,update_order)
           obj.tank_ullage = TankUllage(ullage_fluid,Vtank-Vliq);
           obj.tank_liquid = TankLiquid(liquid_fluid,Vliq);
           obj.Atank = Atank;
           if nargin > 5
                obj.update_order = update_order;
           end
           obj.Vtank = Vtank;
           obj.m = obj.tank_ullage.m + obj.tank_liquid.m;
           
           obj.ode_state = [obj.tank_ullage.m; obj.tank_ullage.m*obj.tank_ullage.fluid.u; obj.tank_liquid.m; obj.tank_liquid.m*obj.tank_liquid.fluid.u];
        end
        function update(obj, ~, ode_state)
            ode_ullage = ode_state(1:length(obj.tank_ullage.ode_state));
            ode_liquid = ode_state(length(obj.tank_ullage.ode_state)+1:end);
            obj.tank_liquid.update([],ode_liquid);
            obj.tank_ullage.V = obj.Vtank - obj.tank_liquid.V;
            obj.tank_ullage.update([],ode_ullage);
            obj.tank_liquid.update_fluid(obj.tank_ullage.fluid.P);
            obj.m = obj.tank_ullage.m + obj.tank_liquid.m;
        end
        function ydot = odestatedot(obj)
           ullage_inlets = {};
           ullage_outlets = {};
           liquid_inlets = {};
           liquid_outlets = {};
           h = obj.hliq;
           % iterate through inlets, determine which node they connect to
           for k = 1:numel(obj.inlet)
                if(obj.inlet{k}.inlet_height >= h)
                    ullage_inlets{end+1} = obj.inlet{k};
                else
                    liquid_inlets{end+1} = obj.inlet{k};
                end
           end
           % iterate through outlets, determine which node they connect to
           for k = 1:numel(obj.outlet)
                if(obj.outlet{k}.inlet_height >= h)
                    ullage_outlets{end+1} = obj.outlet{k};
                else
                    liquid_outlets{end+1} = obj.outlet{k};
                end
           end
           ydot_tank = obj.tank_liquid.odestatedot(liquid_inlets,liquid_outlets);
           ydot_ullage = obj.tank_ullage.odestatedot(ullage_inlets,ullage_outlets,-ydot_tank(1)/obj.tank_liquid.fluid.rho);
           ydot = [ydot_ullage; ydot_tank]; % mdot, udot
       end
        function s = state(obj)
            s.ullage = obj.tank_ullage.state;
            s.liquid = obj.tank_liquid.state;
            s.hliq = obj.hliq;
            s.m = obj.m;
            s.fill_pct = obj.tank_liquid.V/obj.Vtank;
        end
        function h = hliq(obj)
            % calculate current liquid height
            persistent last_Vliq last_hliq
            if isempty(last_hliq)
                last_hliq = 0;
            end
            if isempty(last_Vliq) || obj.tank_liquid.V ~= last_Vliq
                last_Vliq = obj.tank_liquid.V;
            else
                h = last_hliq;
                return
            end
            if ~isa(obj.Atank,'function_handle')
                h = last_Vliq/obj.Atank;
            else
                h = fzero(@(x)integral(obj.Atank,0,x)-last_Vliq,last_hliq);
            end
            last_hliq = h;
        end
        function f = get_fluid(obj, height)
            if height >= obj.hliq
                f = obj.tank_ullage.get_fluid(height);
            else
                f = obj.tank_liquid.get_fluid(height);
            end
        end
    end
end