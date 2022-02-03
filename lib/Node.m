classdef (Abstract) Node  < handle
   properties 
      state; % full state including all variables desired in simulation output
      ode_state; % minimal state representation used for integration
      fluid; % the fluid associated with this object
      volume; % 
   end
   methods
       function update(obj, ode_state) 
          obj.ode_state = ode_state; 
       end
   end
   methods(Abstract)
      ydot = statedot(obj,t,y); % get state derivative
   end
end