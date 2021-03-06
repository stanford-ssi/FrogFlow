classdef Orifice < Conduit
   properties(Access=protected)
      Cd = 0; % discharge coefficient, [0,1] 
      A = 0; % discharge area, m^2
      override_class=[];
   end
   properties
       mdot;
       Udot;
       choked;
       dP;
       dir;
   end
   properties(Hidden,Access=private)
       type_map = {{'IncompressibleLiquid',@Orifice.flowdot_SPI};
                   {'Gas',@Orifice.flowdot_gas};
                   {'SatFluid',@Orifice.flowdot_SPI};};
   end
   methods
       function obj = Orifice(Cd,A,override_typemap)
            if nargin > 2
                if iscell(override_typemap)
                    for i = 1:numel(obj.type_map)
                        if strcmpi(obj.type_map{i}{1},override_typemap{1})
                            obj.type_map{i}{2} = override_typemap{2};
                            break;
                        end
                    end
                end
            end
            obj.Cd = Cd;
            obj.A = A;
       end
       function [mdot, Udot, varargout] = flowdot(obj)
           try
               upstream = obj.inlet.get_fluid(obj.inlet_height);
               downstream = obj.outlet.get_fluid(obj.outlet_height);
           catch 
               mdot = 0;
               Udot = 0;
               dp = 0;
               choke = 0;
               fdir = 0;
               if nargout > 2
                    varargout{1} = dp;
                    varargout{2} = choke;
                    varargout{3} = fdir;
               end
               obj.update(obj,mdot,udot,choke,dp)
               return
           end
           P1 = upstream.P;
           P2 = downstream.P;
           mult = 1;
           if(P1<P2)
                mult = -1;
                hold = upstream;
                upstream = downstream;
                downstream = hold;
           end
           % find fluid type in type map and use corresponding flowdot function
           for i = 1:numel(obj.type_map)
                comp_type = obj.type_map{i}{1};
                comp_func = obj.type_map{i}{2};
                if isa(upstream,comp_type)
                    [mdot, Udot, choke, dp, fdir] = comp_func(upstream,downstream,obj.Cd,obj.A,mult);
                    if nargout > 2
                        varargout{1} = choke;
                        varargout{2} = dp;
                        varargout{3} = fdir;
                    end
                    obj.update(mdot,Udot,choke,dp,fdir);
                    return
                end
           end
           error("Failed to find a suitable Orifice flow calculation for this type of fluid.")
       end
       function update(obj,mdot,udot,choked,dP,dir)
           obj.dP = dP;
           obj.choked = choked;
           obj.mdot = mdot;
           obj.Udot = udot;
           obj.dir = dir;
       end
   end
   methods(Static)
       function [mdot, Udot,varargout] = flowdot_SPI(upstream, downstream,Cd,A,mult)
           P1 = upstream.P;
           P2 = downstream.P;
           dP = P1-P2;
           rho = upstream.rho;
           mdot = mult*sqrt(2*dP*rho)*Cd*A;
           Udot = mdot*upstream.h;
           if nargout > 2
                varargout{1} = 0; % liquid never choked
                varargout{2} = dP;
                varargout{3} = mult;
           end
       end
       function [mdot, Udot,varargout] = flowdot_gas(upstream, downstream,Cd,A,mult)
           Pup = upstream.P; 
           Pdown = downstream.P;
           hup = upstream.h;
           rhoup = upstream.rho;
           gup = upstream.gamma;
           dP = Pup - Pdown;
           if( Pup > Pdown*((gup+1)/2)^(gup/(gup-1)) ) % if choked
               choked = 1;
               mdot = Cd*A*sqrt(gup*Pup*rhoup*(2/(gup+1))^((gup+1)/(gup-1)));
           else % if not choked
               choked = 0;
               mdot = Cd*A*sqrt(2*rhoup*Pup*(gup/(gup-1))*((Pdown/Pup)^(2/gup)-(Pdown/Pup)^((gup+1)/gup)));
           end
           mdot = mult*mdot;
           Udot = mdot*hup;
           if nargout > 2
                varargout{1} = choked;
                varargout{2} = dP;
                varargout{3} = mult;
           end
       end
   end
end