classdef (Abstract) Conduit < Component
    properties(Constant,Hidden)
       Inlet= 1
       Outlet = -1
    end
    properties
       inlet_height = 0;
       outlet_height = 0;
    end
    methods
        function obj = Conduit(child_conduit)
            if nargin == 0
                child_conduit = false;
           end
           obj@Component(child_conduit);
        end
        function attach_inlet_to(obj,comp,height,recip,warning_off)
           if ~isempty(obj.inlet) && (nargin < 5 || ~warning_off)
               warning("Conduits can only have one connection at the inlet - overwriting existing connection.");
           end
           if nargin < 4
              recip = true; % also create the reverse connection
           end
           if nargin < 3
               height = Node.Bottom; % default to attaching at bottom
           end
           obj.inlet = comp;
           obj.inlet_height = height;
           if recip
                comp.attach_outlet_to(obj,height,false); % create reciprocal connection
           end
        end
        function attach_outlet_to(obj,comp,height,recip,warning_off)
            if ~isempty(obj.outlet) && (nargin < 5 || ~warning_off)
               warning("Conduits can only have one connection at the outlet - overwriting existing connection.");
           end
           if nargin < 4
              recip = true; % also create the reverse connection
           end
           if nargin < 3
               height = Node.Bottom; % default to attaching at bottom
           end
           obj.outlet = comp;
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
    end
    methods(Abstract)
        [mdot, Udot] = flowdot(obj);
    end
end