classdef (Abstract) Conduit < handle
    properties
       intensive; % intensive fluid properties
       upstream; % component/node upstream of this conduit (at inlet)
       downstream; % component/node downstream of this conduit (at outlet)
       fluid; % the fluid associated with this object
    end
    methods
        function up = connect_upstream(obj, comp_handle)
            upstream = 
            up = comp_handle;
        end
        
        function check_fluid(obj, new_fluid)
            
        end
    end
end