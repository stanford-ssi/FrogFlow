classdef (Abstract) Tank < Node
    % Basic structure of a "Tank" object, an object owning an UllageNode,
    % containing a Gas fluid, and a LiquidNode, containing a Liquid fluid.
    % 
    % A subclass will need to define the 'update' function, which 
    % determines how the object uses the ode_state (by default, 
    % [m_ullage, U_ullage, m_liquid, U_liquid] ) to set the new fluid
    % states. Additionally, subclasses can add Conduits between the
    % ullage/liquid nodes.
    properties
        m; % total mass, kg
        U; % total extrinsic energy, J
        ullage_node; % node containing the ullage fluid
        liquid_node; % node containing the liquid fluid
    end
    properties(Access=protected)
        dVliqdt; % derivative of volume change
        V; % total volume of the tank, m^3
        A; % cross-sectional area of tank, m^2, assumed simple prism
        fluid = [];
        ode_state = []; 
    end
    properties(Dependent)
        zliq; % height of liquid
        fill_pct; % fractional fill level of liquid
        zmax; % max height of liquid (tank height)
    end
    methods
        function obj = Tank(ullage_node,liquid_node,Vtank,Atank,child_node,update_order)
            if nargin <= 4
                child_node = false;
            end
            if nargin <= 5
                update_order = 0;
            end
            obj@Node(child_node,update_order); % not a child node

           ullage_node.set_tank_parent(obj);
           liquid_node.set_tank_parent(obj);
           obj.ullage_node = ullage_node;
           obj.liquid_node = liquid_node;
           obj.A = Atank;
           obj.V = Vtank;
           obj.m = obj.ullage_node.m + obj.liquid_node.m;
           obj.U = obj.ullage_node.m*obj.ullage_node.get_fluid().u + obj.liquid_node.m*obj.liquid_node.get_fluid().u;
           obj.ode_state = [obj.ullage_node.m; obj.ullage_node.m*obj.ullage_node.get_fluid().u; obj.liquid_node.m; obj.liquid_node.m*obj.liquid_node.get_fluid().u];
        end
        function ydot = odestatedot(obj)
           ullage_inlets = {};
           ullage_outlets = {};
           liquid_inlets = {};
           liquid_outlets = {};

           % iterate through inlets, determine which node they connect to
           for k = 1:numel(obj.inlet)
                if(obj.inlet{k}.inlet_height >= obj.zliq)
                    ullage_inlets{end+1} = obj.inlet{k};
                else
                    liquid_inlets{end+1} = obj.inlet{k};
                end
           end
           % iterate through outlets, determine which node they connect to
           for k = 1:numel(obj.outlet)
                if(obj.outlet{k}.inlet_height >= obj.zliq)
                    ullage_outlets{end+1} = obj.outlet{k};
                else
                    liquid_outlets{end+1} = obj.outlet{k};
                end
           end
           ydot_liquid = obj.liquid_node.odestatedot(liquid_inlets,liquid_outlets);
           obj.dVliqdt = ydot_liquid(1)/obj.liquid_node.get_fluid().rho;
           ydot_ullage = obj.ullage_node.odestatedot(ullage_inlets,ullage_outlets,-ydot_liquid(1)/obj.liquid_node.get_fluid().rho);
           ydot = [ydot_ullage; ydot_liquid]; % mdot, udot
        end
        function f = get_fluid(obj, height)
            if nargin == 1
                f = [];
                return
            end
            if height >= obj.zliq
                f = obj.ullage_node.get_fluid(height);
            else
                f = obj.liquid_node.get_fluid(height);
            end
        end
        function update(obj,t,ode_state)
            ode_ullage = ode_state(1:2); % ullage ode
            ode_liquid = ode_state(3:4); % liquid ode
            % Update nodes (just stores ode_state)
            obj.liquid_node.update(t,ode_liquid);
            obj.ullage_node.update(t,ode_ullage);
        end
        function zm = get.zmax(obj)
            zm = obj.V/obj.A;
        end
        function zl = get.zliq(obj)
            zl = obj.liquid_node.V/obj.V;
        end
        function fp = get.fill_pct(obj)
            fp = obj.liquid_node.V/obj.V;
        end
    end
end