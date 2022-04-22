classdef DataHandle < handle
    % Simple class for storing data as handles - makes the idea of "static
    % variables" possible without using persistent vars.
    properties 
       data = []; 
    end
end