classdef SimpleNode < Node
    % just making a node to test simulation!
    properties
        num;
    end
    methods
        function obj = SimpleNode(update_order)
           obj = obj@Node();
           obj.num = SimpleNode.newsimple();
           if nargin > 0
              obj.update_order = update_order; 
           end
        end
        function s = get_fluid(~) % get fluid at the requested height
            s = 0;
        end
        function ydot = statedot(~) % get state derivative
            ydot = 0;
        end
        function update(obj,~)
           disp(obj.num); 
        end
    end
   methods(Static)
       function nodenum = newsimple()
          persistent n
          if isempty(n)
              n = 0;
          end
          n = n + 1;
          nodenum = n;
       end
   end
end