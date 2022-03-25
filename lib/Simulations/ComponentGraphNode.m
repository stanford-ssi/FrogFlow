classdef ComponentGraphNode < handle
    properties
       comp_handle;
       chain_id;
    end
    methods
        function obj = ComponentGraphNode(comp,chain_id)
            obj.comp_handle = comp;
            obj.chain_id = [chain_id];
        end
    end
    methods(Static)
        function chid = newchain(~)
           persistent chain_num
           if isempty(chain_num) || nargin > 0
              chain_num = 0; 
           end
           chain_num = chain_num + 1;
           chid = chain_num;
        end
    end
end