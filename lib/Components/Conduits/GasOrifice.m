classdef GasOrifice < Conduit
   properties
      Cd = 0; % discharge coefficient, [0,1] 
      A = 0; % discharge area, m^2
      dP = 0; % delta pressure
      choked = 0; % choked status
      mdot = 0; % current mass flow
   end
   methods
       function mdot = get_mdot(obj)
           P1 = obj.upstream.intensive.P;
           P2 = obj.downstream.intensive.P;
           if(P1>P2)
               Pup = P1; Pdown = P2;
               rhoup = obj.upstream.intensive.rho;
               gup = obj.upstream.gamma;
           else
               Pup = P2; Pdown = P1;
               rhoup = obj.downstream.intensive.rho;
               gup = obj.downstream.gamma;
           end
           if( Pup > Pdown*((gup+1)/2)^(gup/(gup-1)) ) % if choked
               obj.choked = 1;
               mdot = obj.Cd*obj.A*sqrt(gup*rhoup*pup*(2/(gup+1))^((gup+1)/(gup-1)));
           else % if not choked
               obj.choked = 0;
               mdot = obj.Cd*obj.A*sqrt(2*rhoup*pup*(gup/(gup-1))*((Pdown/Pup)^(2/gup)-(Pdown/Pup)^((gup+1)/gup)));
           end
           obj.mdot = mdot;
       end
   end
end