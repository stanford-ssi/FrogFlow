classdef Simulation < handle
   properties
       state_record; % full record
       ode_state; % only the state variables that get integrated
       state; % full state, including derived values
       component_handles; % array of all constituent components
       update_list; % ordered array of nodes for updating
       update_step = 0;
       t_ind = 1;
   end
   methods(Access=public)
       function out = run(obj, tspan, options)
           % TODO - include user-selected options for integration or
           % modeling
           obj.initialize_record(tspan); % initialize the record, clearing and making arrays
           opts = odeset('Events',@(t,y) obj.terminalfunction());
           [~] = ode15s(@(t,y)obj.xstatedot(t,y),tspan,obj.odestate,opts);
           obj.trim_record(obj.record()); % record final state and trim record to final length
           out = obj.state_record; % output the state_record
       end
       function comp = add_component(obj, comp_handle)
          obj.component_handles.append(comp_handle);
          if isa(comp_handle,'Node')
             obj.update_list.append(comp_handle); 
          end
          comp = comp_handle;
       end
   end
   methods(Access=private)
       function record(obj)
          % for each component, record the full state
          for comp_handle = obj.component_handles
              comp_name = comp_handle.name;
              fn = fieldnames(comp_handle.state); 
              for k=1:numel(fn)
                  % Add data to the record
                  obj.state_record.(comp_name).(fn{k})(obj.t_ind) = comp_handle.state.(fn{k});
              end
          end
          obj.t_ind = obj.t_ind + 1; % increment timestep index
       end
       function initialize_record(obj, tspan)
           obj.t_ind = 1; % reset timestep index
          for comp_handle = obj.component_handles
              comp_name = comp_handle.name;
              fn = fieldnames(comp_handle.state); 
              for k=1:numel(fn)
                  % Initialize arrays
                  obj.state_record.(comp_name).(fn{k}) = zeros(size(tspan));
              end
          end
       end
       function trim_record(obj)
           for comp_handle = obj.component_handles
              comp_name = comp_handle.name;
              fn = fieldnames(comp_handle.state); 
              for k=1:numel(fn)
                  % Trim unset data from the output record
                  obj.state_record.(comp_name).(fn{k}) = obj.state_record.(comp_name).(fn{k})(1:obj.t_ind+1);
              end
          end
       end
       function ydot = xstatedot(obj, t, ode_state)
          ydot = zeros('like', ode_state);
          % Update all nodes
          i = 1;
          for node = obj.update_list
              fin = length(node.ode_state) - 1;
              ydot(i:i+fin) = node.update(ode_state(i:i+fin));
              i = i + fin;
          end
          % Get state derivative
          i = 1;
          for node = obj.update_list
              fin = length(node.ode_state) - 1;
              ydot(i:i+fin) = node.statedot(t,ode_state(i:i+fin));
              i = i + fin;
          end
          obj.record(); % record state
       end
   end
end