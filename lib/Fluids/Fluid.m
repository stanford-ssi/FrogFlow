classdef (Abstract) Fluid < handle
   properties(Constant,Hidden)
      Ru = 8.31446261815324; % universal gas constant, J/K/mol 
      NA = 6.0221409E23; % avogadro's number, #/mole
      kB = 1.380649E-23; % boltzmann constant, J/K
      hplanck = 6.62607004E-34; % planck's constant, m^2 kg/s
   end
   properties
       P; % pressure, Pa
       T; % temperature, K
       rho; % density, kg/m3
       cp; % specific heat at constant pressure, J/kg/K
       cv; % specific heat at constant volume, J/kg/K
       u; % specific internal energy, J/kg
       h; %specific enthalpy, J/kg
       s; % specific entropy, J/kg/K
       mu; % dynamic viscosity, Pa*s
       c; % speed of sound, m/s
       mw; % molecular weight, kg/mol
       k; % thermal conductivity, W/m/K
       beta; % coefficient of thermal expansion, 1/K
   end
   methods
        function dPdT(~); error("Not implemented for this fluid"); end
        function dPdrho(~); error("Not implemented for this fluid"); end
        function dudrho(~); error("Not implemented for this fluid"); end

        function update_PT(~); error("Not implemented for this fluid"); end
        function update_rhoP(~); error("Not implemented for this fluid"); end
        function update_rhoT(~); error("Not implemented for this fluid"); end
        function update_rhoh(~); error("Not implemented for this fluid"); end
        function update_rhos(~); error("Not implemented for this fluid"); end
        function update_rhou(~); error("Not implemented for this fluid"); end
        function update_sT(~); error("Not implemented for this fluid"); end
        function update_uT(~); error("Not implemented for this fluid"); end
        function update_uP(~); error("Not implemented for this fluid"); end
        function update_hT(~); error("Not implemented for this fluid"); end
        function update_hP(~); error("Not implemented for this fluid"); end

       function d = density(obj)
          d = obj.rho; 
       end
       function p = pressure(obj)
          p = obj.P; 
       end
       function r = R(obj)
          r = obj.Ru/obj.mw; 
       end
       function t = temperature(obj)
          t = obj.T;
       end
       function t = temp(obj)
          t = obj.T;
       end
       function s = state(obj)
           % On request for state, return all fluid properties as struct
           props = properties(obj);
           for iprop = 1:length(props)
                thisprop = props{iprop};
                s.(thisprop) = obj.(thisprop);
           end
       end
   end
end