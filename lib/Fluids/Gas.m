classdef (Abstract) Gas  < Fluid
   methods
       function G = gamma(obj)
          G = obj.cp/obj.cv; 
       end
       function G = g(obj)
          G = obj.cp/obj.cv; 
       end
   end
end
