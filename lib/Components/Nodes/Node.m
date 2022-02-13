classdef (Abstract) Node  < Component
   properties(Constant)
       Top = Inf;
       Bottom = 0 ;
   end
   properties 
      state; % full state including all variables desired in simulation output
      update_order = 0 % order in which this node should be updated - higher number = update earlier
   end
   methods
       function update(obj, ode_state) 
          obj.ode_state = ode_state; 
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
   end
   methods(Abstract)
      s = get_fluid(obj,height); % get fluid at the requested height
      ydot = statedot(obj,t,y); % get state derivative
   end
end