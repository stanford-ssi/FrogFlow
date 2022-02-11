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
      s = update_PT(obj,P,T); 
      s = update_rhoP(obj,rho,P);
      s = update_rhoT(obj,rho,T);
      s = update_rhoh(obj,rho,h);
      s = update_rhos(obj,rho,s);
      s = update_sT(obj,s,T);
      s = update_uT(obj,u,T);
      s = update_hT(obj,h,T);
      s = update_hP(obj,h,P);
      s = update(obj); % a default update method called if properties are set directly
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
       function s = state(obj)
           % On request for state, return all fluid properties
           props = properties(obj);
           for iprop = 1:length(props)
                thisprop = props{iprop};
                %%%Add logic here if you want to work with select properties
                s.thisprop = obj.(thisprop);
           end
       end
   end
end