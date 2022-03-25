classdef (Abstract) Component < handle
    properties
        inlet = {} % array of component handles connected to inlet
        outlet = {} % array of component handles connected to outlet
        record; % struture holding arrays of integrated data
    end
    methods
        function obj = Component(child_component)
           if isempty(Component.sim)
              error("Cannot create components before creating a Simulation object to own them.");
           end
           if nargin == 0
               child_component = false;
           end
           if ~child_component
                Component.sim.add_component(obj); % add this component to the simulation for auto-updating
           end
        end
        function initialize_record(obj, datalen)
            s = obj.state();
            fn = fieldnames(s);
            for k = 1:numel(fn)
                if isstruct(s.(fn{k}))
                    fn2 = fieldnames(s.(fn{k}));
                    for l = 1:numel(fn2)
                        obj.record.(fn{k}).(fn2{l}) = zeros(datalen,1);
                    end
                else
                    obj.record.(fn{k}) = zeros(datalen,1);
                end
            end
        end
        function record_state(obj, t_ind)
            % add all elements in state to this object's record
            s = obj.state();
            fn = fieldnames(s);
            for k = 1:numel(fn)
                if isstruct(s.(fn{k}))
                    fn2 = fieldnames(s.(fn{k}));
                    for l = 1:numel(fn2)
                        obj.record.(fn{k}).(fn2{l})(t_ind) = s.(fn{k}).(fn2{l});
                    end
                else
                    obj.record.(fn{k})(t_ind) = s.(fn{k});
                end
            end
        end
        function trim_record(obj, last_ind)
            s = obj.record();
            fn = fieldnames(s);
            for k = 1:numel(fn)
                if isstruct(s.(fn{k}))
                    fn2 = fieldnames(s.(fn{k}));
                    for l = 1:numel(fn2)
                        obj.record.(fn{k}).(fn2{l}) = obj.record.(fn{k}).(fn2{l})(1:last_ind);
                    end
                else
                    obj.record.(fn{k}) = obj.record.(fn{k})(1:last_ind);
                end
            end
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
        s = state(obj); % return the full state of the object
    end
end