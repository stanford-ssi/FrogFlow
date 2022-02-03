classdef (Abstract) Fluid < handle
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
   end
   methods(Abstract)
      update_PT(P,T); 
      update_rhoP(rho,P);
      update_rhoT(rho,T);
      update_sT(s,T);
      update_rhos(rho,s);
      update_uT(u,T);
      update(); % a default update method called if properties are set directly
   end
   methods 
       function d = density(obj)
          d = obj.rho; 
       end
       function p = pressure(obj)
          p = obj.P; 
       end
       function t = temperature(obj)
          t = obj.T;
       end
       function t = temp(obj)
          t = obj.T;
       end
   end
end