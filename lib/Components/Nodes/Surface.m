classdef (Abstract) Surface  < Component
    properties
        T; % temp of solid, K
        U; % extensive energy, K
    end
    properties(SetAccess=protected)
        c; % specific heat capacity, J/kg/K
    end
    properties(Access=protected)
        m; % mass of solid, kg
        rho; %density of solid, kg
        fluid = []; % no Fluid object is owned by this node!
        update_order; % order in which this node should be updated - higher number = update earlier
        ode_state; % most recent minimal state representation from integration
    end
    properties(Dependent)
        mc;
    end
    methods(Abstract)
        l = length(obj); % get length for representative area in convection calcs
        a = area(obj); % get area for representative area in convection calcs
    end
    methods
        function obj = Surface(rho,V,c,T)
            obj.rho = rho;
            obj.m = rho*V;
            obj.T = T;
            obj.U = cv*T;
            obj.c = c;
            obj.ode_state = rho*V*cv*T;
        end
        function update(obj, ~, odestate) % update based on new ode_state
            % ode_state = [m,U]
            obj.m = odestate(1);
            obj.U = odestate(2);
            obj.T = obj.U/obj.c;
        end
        function f = get_fluid(~) % get fluid at specified height
            f = []; % return empty to signify no fluid
        end
    end
end