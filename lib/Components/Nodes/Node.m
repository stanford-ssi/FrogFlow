classdef (Abstract) Node  < Component
   properties(Constant,Hidden)
       Top = Inf;
       Bottom = 0 ;
   end
   properties(Abstract,Access=protected)
      fluid;
      ode_state; % most recent minimal state representation from integration
   end
   properties(Hidden)
      update_order = 0; % order in which this node should be updated - higher number = update earlier
   end
   methods
       function obj = Node(child_node,update_order)
           if nargin == 0
                child_node = false;
           end
           obj@Component(child_node);
           if nargin > 1
               obj.update_order = update_order;
           end
       end
       function detach_outlets(obj)
            for k=1:length(obj.outlet)
                if obj.outlet{k} ~= 0
                    comp = obj.outlet{k};
                    obj.outlet{k} = 0;
                    comp.detach_inlets();
                end
            end
            obj.outlet = {};
        end
        function detach_inlets(obj)
            for k=1:length(obj.inlet)
                if obj.inlet{k} ~= 0
                    comp = obj.inlet{k};
                    obj.inlet{k} = 0;
                    comp.detach_outlets();
                end
            end
            obj.inlet = {};
       end
       function attach_inlet_to(obj,comp,height,recip)
           if nargin < 4
              recip = true; % also create the reverse connection
           end
           if nargin < 3
               height = obj.Bottom; % default to attaching at bottom
           end
           obj.inlet{end+1} = comp;
           if recip
               comp.attach_outlet_to(obj,height,false); % create reciprocal connection
           end
       end
        function attach_outlet_to(obj,comp,height,recip)
           if nargin < 4
              recip = true; % also create the reverse connection
           end
           if nargin < 3
               height = obj.Bottom; % default to attaching at bottom
           end
           obj.outlet{end+1} = comp;
           if recip
               comp.attach_inlet_to(obj,height,false); % create reciprocal connection
           end
        end
       function ydot = odestatedot(obj)
           mdot = 0;
           Udot = 0;
           % iterate through inlets, add mdot and udot
           for k = 1:numel(obj.inlet)
                [md, ud] = obj.inlet{k}.flowdot();
                mdot = mdot + md;
                Udot = Udot + ud;
           end
           % iterate through outlets, subtract mdot and udot
           for k = 1:numel(obj.outlet)
                [md, ud] = obj.outlet{k}.flowdot();
                mdot = mdot - md;
                Udot = Udot - ud;
           end
           ydot = [mdot; Udot]; % mdot, udot
       end
       function odest = get_ode_state(obj)
            odest = obj.ode_state;
       end
   end
   methods(Abstract)
      update(obj, t, odestate); % update based on new ode_state
      f = get_fluid(obj, height); % get fluid at specified height
   end
end