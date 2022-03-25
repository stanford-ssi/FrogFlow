classdef Simulation < handle
   properties
       state_record; % full record
       state; % full state, including derived values
       component_handles = {}; % array of all constituent components
       update_list = {}; % ordered array of nodes for updating
       t_ind = 1;
       comp_graph = ComponentGraph();
       end_sim = false;
       msg_out;
       time = [];
   end
   methods(Access=public)
       function obj = Simulation()
          Component.sim(obj); % pass new simulation object to components for building component tree!
       end
       function run(obj, tspan, options)
           obj.clear_flag();
           % Create update list from component graph
           obj.update_list = obj.comp_graph.make_updatelist(obj.component_handles);
           obj.initialize_record(tspan); % initialize the record, clearing and making arrays
           opts = odeset('Events',@(t,y) obj.terminalfunction(),'AbsTol',1E-6,'RelTol',1E-6);
           if nargin > 2
                opts = odeset(options,opts);
           end
           [obj.time,y] = ode15s(@(t,y)obj.statedot(t,y),tspan,obj.ode_state,opts);
           obj.record(obj.time,y);
           if ~isempty(obj.msg_out)
                disp(obj.msg_out);
           end
       end
       function add_component(obj, comp_handle)
          obj.component_handles{end+1} = comp_handle;
       end
       function disp(obj)
           obj.comp_graph.chain(obj.component_handles);
           disp(obj.comp_graph);
       end
       function set_flag(obj,msg)
           
           obj.end_sim = true;
           if nargin>1
                obj.msg_out = msg;
           end
       end
       function clear_flag(obj)
           obj.msg_out = [];
           obj.end_sim = false;
       end
   end
   methods(Access=private)
       function [value,isterminal,direction] = terminalfunction(obj)
           % Terminal function for ODE - can be flagged to end simulation
           if obj.end_sim
                value = 0;
                isterminal = 1;
                direction = 0;
           else
                value = 1;
                isterminal = 1;
                direction = 0;
           end
       end
       function record(obj,t,y)
          % After getting integrated data, run back through and record at
          % each requested time step the full state.
          obj.initialize_record(t);
          for k = 1:length(t)
              i = 1;
              for j = 1:numel(obj.update_list)
                  node = obj.update_list{j};
                  if ~isempty(node.ode_state)
                      fin = length(node.ode_state) - 1;
                      node.update(t(k), y(k,i:i+fin));
                      i = i + fin + 1;
                  end
              end
              for j = 1:numel(obj.component_handles)
                  comp = obj.component_handles{j};
                  comp.record_state(k);
              end
          end
          obj.t_ind = obj.t_ind + 1; % increment timestep index
       end
       function initialize_record(obj, tspan)
           % Prepare all components for data recording by resetting their
           % record array
           obj.t_ind = 1; % reset timestep index
           tlen = length(tspan);
          for i = 1:numel(obj.component_handles)
              comp_handle = obj.component_handles{i};
              comp_handle.initialize_record(tlen);
          end
       end
       function odes = ode_state(obj)
          % Get the minimal state representation
          odes = [];
          % Get odestate from each node
          i = 1;
          for j = 1:numel(obj.update_list)
              node = obj.update_list{j};
              if ~isempty(node.ode_state)
                  fin = length(node.ode_state) - 1;
                  odes(i:i+fin) = node.ode_state;
                  i = i + fin + 1;
              end
          end
       end
       function ydot = statedot(obj, t, state)
          % Calculate the derivative vector of the system
          ydot = zeros(size(state));
          % Update all nodes
          i = 1;
          for j = 1:numel(obj.update_list)
              node = obj.update_list{j};
              if ~isempty(node.ode_state)
                  fin = length(node.ode_state) - 1;
                  node.update(t, state(i:i+fin));
                  i = i + fin + 1;
              end
          end
          % Get state derivative
          i = 1;
          for j = 1:numel(obj.update_list)
              node = obj.update_list{j};
              if ~isempty(node.ode_state)
                  fin = length(node.ode_state) - 1;
                  ydot(i:i+fin) = node.odestatedot();
                  i = i + fin + 1;
              end
          end
       end
   end
end