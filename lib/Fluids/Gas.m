classdef (Abstract) Gas  < Fluid
   properties(Constant)
      Ru = 8.31446261815324; % universal gas constant, J/K/mol 
      NA = 6.0221409E23; % avogadro's number, #/mole
      hplanck = 6.62607004E-34; % planck's constant, m^2 kg/s
   end
   methods
      function r = R(obj)
          r = obj.Ru/obj.mw; 
       end
       function G = gamma(obj)
          G = obj.cp/obj.cv; 
       end
       function G = g(obj)
          G = obj.cp/obj.cv; 
       end
   end
end
