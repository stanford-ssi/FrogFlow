classdef (Abstract) Node  < Component
   properties(Constant)
       Top = Inf;
       Bottom = 0 ;
   end
   properties(Abstract)
      fluid; % Fluid object owned by this node
      ode_state; % most recent minimal state representation from integration
      update_order; % order in which this node should be updated - higher number = update earlier
   end
   methods
       function obj = Node(child_node)
           if nargin == 0
                child_node = false;
           end
           obj@Component(child_node);
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
   end
   methods(Abstract)
      update(obj, t, odestate); % update based on new ode_state
      get_fluid(obj, height); % get fluid at specified height
   end
end