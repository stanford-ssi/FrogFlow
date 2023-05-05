classdef Simulation < handle
   properties
       state_record; % full record
       state; % full state, including derived values
       component_handles = {}; % array of all constituent components
       update_list = {}; % ordered array of nodes for updating
       record_list = {}; % array of components for recording
       comp_graph = ComponentGraph();
       end_sim_flag = false;
       continue_sim_flag = false;
       time = [];
       last_t = 0;
       t_step = 0; 
       accel = 9.80665; %m/s2
   end
   methods(Access=public)
       function obj = Simulation()
          Component.sim(obj); % pass new simulation object to components for building component tree!
       end
       function run(obj, tspan, options)
           % Create update list from component graph
           obj.update_list = obj.comp_graph.make_updatelist(obj.component_handles);
           opts = odeset('Events',@(t,y) obj.terminalfunction(),'AbsTol',1E-6,'RelTol',1E-6);
           if nargin > 2
                opts = odeset(opts,options); % add in user odeset options
           end
           SimEvent.clear_events(); % reset events
           [obj.time,y] = obj.integrate(tspan,opts);
           while obj.continue_sim_flag && obj.time(end) < tspan(2)-1E-10
                new_tspan = [obj.time(end)+1E-10 tspan(2)];
                [newt, newy] = obj.integrate(new_tspan,opts);
                obj.time =  [obj.time; newt];
                y = [y; newy];
           end
           obj.record(obj.time,y);
       end
       function add_component(obj, comp_handle)
          obj.component_handles{end+1} = comp_handle;
       end
       function disp(obj)
           obj.comp_graph.chain(obj.component_handles);
           disp(obj.comp_graph);
       end
       function clear_flags(obj)
           obj.end_sim_flag = false;
           obj.continue_sim_flag = false;
       end
       function end_sim(obj)
           obj.end_sim_flag = true;
       end
       function continue_sim(obj)
           obj.continue_sim_flag = true;
           obj.end_sim();
       end
   end
   methods(Access=private)
       function [t, y] = integrate(obj,tspan,opts)
           obj.clear_flags();
           [t,y] = ode15s(@(t,y)obj.statedot(t,y),tspan,obj.ode_state(),opts);
           SimEvent.update_events();
       end
       function [value,isterminal,direction] = terminalfunction(obj)
           % Terminal function for ODE - can be flagged to end simulation
           if obj.end_sim_flag
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
          SimEvent.record_events(); % switch events to recording mode
          for k = 1:length(t)
              i = 1;
              for j = 1:numel(obj.update_list)
                  node = obj.update_list{j};
                  odest = node.get_ode_state();
                  if ~isempty(odest)
                      fin = length(odest) - 1;
                      node.update(t(k), y(k,i:i+fin));
                      i = i + fin + 1;
                  end
              end
              for j = 1:numel(obj.update_list)
                  node = obj.update_list{j};
                  node.odestatedot(); % calc statedot to update inlets/outlets
              end
              for j = 1:numel(obj.component_handles)
                  comp = obj.component_handles{j};
                  comp.record_state(k);
              end
          end
       end
       function initialize_record(obj, tspan)
           % Prepare all components for data recording by resetting their
           % record array
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
              odest = node.get_ode_state();
              if ~isempty(odest)
                  fin = length(odest) - 1;
                  odes(i:i+fin) = odest;
                  i = i + fin + 1;
              end
          end
       end
       function ydot = statedot(obj, t, state)
          obj.t_step = t - obj.last_t; % update time step for use in numerical differentiation
          obj.last_t = t; % update last time for next t step calc
          % Calculate the derivative vector of the system
          ydot = zeros(size(state));
          % Update all nodes
          i = 1;
          for j = 1:numel(obj.update_list)
              node = obj.update_list{j};
              odest = node.get_ode_state();
              if ~isempty(odest)
                  fin = length(odest) - 1;
                  node.update(t, state(i:i+fin));
                  i = i + fin + 1;
              end
          end
          % Get state derivative
          i = 1;
          for j = 1:numel(obj.update_list)
              node = obj.update_list{j};
              odest = node.get_ode_state();
              if ~isempty(odest)
                  fin = length(odest) - 1;
                  ydot(i:i+fin) = node.odestatedot();
                  i = i + fin + 1;
              end
          end
       end
   end
end