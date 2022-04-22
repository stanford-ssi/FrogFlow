classdef (Abstract) Component < handle
    properties
        record; % struture holding arrays of integrated data
    end
    properties(Hidden)
        inlet = {} % array of component handles connected to inlet
        outlet = {} % array of component handles connected to outlet
        ischild; % is this Component a child
    end
    methods
        function obj = Component(child_component)
           if isempty(Component.sim)
              error("Cannot create components before creating a Simulation object to own them.");
           end
           if nargin == 0
               child_component = false;
           end
            obj.ischild = child_component;
            Component.sim.add_component(obj); % add this component to the simulation for auto-updating
        end
        function initialize_record(obj, datalen)
            s = obj.state();
            fn = fieldnames(s);
            for k = 1:numel(fn)
                if isstruct(s.(fn{k}))
                    if isfield(obj.record,fn{k})
                        obj.record.(fn{k}) = obj.initialize_nested_record(datalen,DataStruct(s.(fn{k})),DataStruct(obj.record.(fn{k})));
                    else
                        obj.record.(fn{k}) = obj.initialize_nested_record(datalen,DataStruct(s.(fn{k})));
                    end
                else
                    obj.record.(fn{k}) = zeros(datalen,1);
                end
            end
        end
        function obj_rec = initialize_nested_record(obj,datalen,s,obj_rec)
            s = s.data;
            if nargin == 4
                obj_rec = obj_rec.data;
            end
            fn = fieldnames(s);
            for k = 1:numel(fn)
                if isstruct(s.(fn{k}))
                    if nargin == 4
                        obj_rec.(fn{k}) = obj.initialize_nested_record(datalen,DataStruct(s.(fn{k})),DataStruct(obj_rec.(fn{k})));
                    else
                        obj_rec.(fn{k}) = obj.initialize_nested_record(datalen,DataStruct(s.(fn{k})));
                    end
                else
                    obj_rec.(fn{k}) = zeros(datalen,1);
                end
            end
        end
        function record_state(obj, t_ind)
            % add all elements in state to this object's record
            s = obj.state();
            fn = fieldnames(s);
            for k = 1:numel(fn)
                if isstruct(s.(fn{k}))
                    if isfield(obj.record,fn{k})
                        obj.record.(fn{k}) = obj.record_nested_state(t_ind,DataStruct(s.(fn{k})),DataStruct(obj.record.(fn{k})));
                    else
                        obj.record.(fn{k}) = obj.record_nested_state(t_ind,DataStruct(s.(fn{k})));
                    end
                else
                    obj.record.(fn{k})(t_ind) = s.(fn{k});
                end
            end
        end
        function obj_rec = record_nested_state(obj,t_ind,s,obj_rec)
            s = s.data;
            if nargin == 4
                obj_rec = obj_rec.data;
            end
            fn = fieldnames(s);
            for k = 1:numel(fn)
                if isstruct(s.(fn{k}))
                    if nargin == 4
                        obj_rec.(fn{k}) = obj.record_nested_state(t_ind,DataStruct(s.(fn{k})),DataStruct(obj_rec.(fn{k})));
                    else
                        obj_rec.(fn{k}) = obj.record_nested_state(t_ind,DataStruct(s.(fn{k})));
                    end
                else
                    obj_rec.(fn{k})(t_ind) = s.(fn{k});
                end
            end
        end
        function trim_record(obj, last_ind)
            s = obj.record();
            fn = fieldnames(s);

            for k = 1:numel(fn)
                if isstruct(s.(fn{k}))
                    if isfield(obj.record,fn{k})
                        obj.record.(fn{k}) = obj.trim_nested_state(t_ind,DataStruct(s.(fn{k})),DataStruct(obj.record.(fn{k})));
                    else
                        obj.record.(fn{k}) = obj.trim_nested_state(t_ind,DataStruct(s.(fn{k})));
                    end
                else
                    obj.record.(fn{k}) = obj.record.(fn{k})(1:last_ind);
                end
            end
        end
        function obj_rec = trim_nested_state(obj,last_ind,s,obj_rec)
            s = s.data;
            if nargin == 4
                obj_rec = obj_rec.data;
            end
            fn = fieldnames(s);
            for k = 1:numel(fn)
                if isstruct(s.(fn{k}))
                    if nargin == 4
                        obj_rec.(fn{k}) = obj.trim_nested_state(datalen,s.(fn{k}),obj_rec.(fn{k}));
                    else
                        obj_rec.(fn{k}) = obj.trim_nested_state(datalen,s.(fn{k}));
                    end
                else
                    obj_rec.(fn{k}) = obj_rec.(fn{k})(1:last_ind);
                end
            end
        end
        function s = state(obj)
           % On request for state, return simulated properties as struct
           props = properties(obj); % any non-hidden variable is a simulated property!
           exclude_props = {'record'}; % don't include the record in state!
           for iprop = 1:length(props)
                thisprop = props{iprop};
                if ~any(strcmp(exclude_props,thisprop))
                    if ~isa(obj.(thisprop),'Component') 
                        s.(thisprop) = obj.(thisprop);
                    end
                end
           end
           if isa(obj,'Node')
               fl = obj.get_fluid();
               if ~isempty(fl)
                    stateprops = properties(fl);
                    for istateprop = 1:length(stateprops)
                        s.(stateprops{istateprop}) = fl.(stateprops{istateprop});
                    end
               end
           end
        end
        function inl = get_inlet(obj)
            inl = obj.inlet;
        end
        function outl = get_outlet(obj)
            outl = obj.outlet;
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
    end
end