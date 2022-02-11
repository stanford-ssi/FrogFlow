classdef (Abstract) Component < handle
    properties
        inlet = {} % array of component handles connected to inlet
        outlet = {} % array of component handles connected to outlet
        update_order = 0 % order in which this component should be updated - higher number = update earlier
    end
    methods
        function obj = Component()
           if isempty(Component.sim)
              error("Cannot create components before creating a Simulation object to own them.");
           end
           Component.sim.add_component(obj); % add this component to the simulation
        end
    end
    methods(Static)
        function s = sim(setsim)
           persistent thissim
           if nargin > 0
               thissim = setsim;
           end
           s = thissim;
        end
    end
    methods(Abstract)
        c = attach_inlet_to(obj,comp);
        c = attach_outlet_to(obj,comp);
        s = get_fluid(obj,heightdir); % get fluid state (may depend on height or direction of inquest)
    end
end