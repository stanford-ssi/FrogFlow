classdef (Abstract) Conduit < Component
    properties(Constant)
       Inlet= 1
       Outlet = -1
    end
    properties
       inlet_height = 0;
       outlet_height = 0;
    end
    methods
        function attach_inlet_to(obj,comp,height,recip)
           if ~isempty(obj.inlet)
               warning("Conduits can only have one connection at the inlet - overwriting existing connection.");
           end
           if nargin < 4
              recip = false; % also create the reverse connection
           end
           if nargin < 3
               height = Node.Bottom; % default to attaching at bottom
           end
           obj.inlet = comp_handle;
           obj.inlet_height = height;
           if recip
                comp.attach_outlet_to(obj,height,false); % create reciprocal connection
           end
        end
        function attach_outlet_to(obj,comp,height,recip)
            if ~isempty(obj.inlet)
               warning("Conduits can only have one connection at the outlet - overwriting existing connection.");
           end
           if nargin < 4
              recip = false; % also create the reverse connection
           end
           if nargin < 3
               height = Node.Bottom; % default to attaching at bottom
           end
           obj.outlet = comp_handle;
           obj.outlet_height = height;
           if recip
                comp.attach_inlet_to(obj,height,false); % create reciprocal connection
           end
        end
        function s = get_fluid(obj, dir)
            if nargin < 2 || dir == obj.Inlet
                comp = obj.inlet;
                h = obj.inlet_height;
            else
                comp = obj.outlet;
                h = obj.outlet_height;
            end
            if isa(comp,'Conduit')
                s = comp.get_fluid(dir);
            else
                s = comp.get_fluid(h); 
            end
        end
        function validate_fluid(obj, new_fluid)
            if (isempty(obj.fluid))
                obj.fluid = new_fluid;
            elseif ~(new_fluid == obj.fluid)
                error("Cannot connect two components with different fluids!"); 
            end
        end
    end
end