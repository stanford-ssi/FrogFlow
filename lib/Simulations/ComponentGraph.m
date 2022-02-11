classdef ComponentGraph < handle
   properties
      component_chain = {};
      update_order = {};
   end
   properties(Constant)
      Inlet = 0;
      Outlet = 1;
      Neither = 2;
   end
   methods
       function update_list =  get_update_order(obj, comp_list)
           update_list = [];
           
       end
       function disp(obj)
           chain_size = size(obj.component_chain);
           chainid_tree = cell(chain_size);
           maxlen = zeros(1,chain_size(2));
           for i = 1:chain_size(1)
               for j = 1:chain_size(2)
                   if ~isempty(obj.component_chain{i,j})
                        chainid_tree{i,j} = obj.component_chain{i,j}.chain_id;
                        maxlen(j) = max(maxlen(j),length(obj.component_chain{i,j}.chain_id));
                   end
               end
           end
           for i = 1:chain_size(1)
               mystr = "";
               for j = 1:chain_size(2)
                   mystr = append(mystr, "[ ");
                   for k = 1:maxlen(j)
                       if ~isempty(obj.component_chain{i,j}) && k <= length(obj.component_chain{i,j}.chain_id)
                           mystr= append(mystr,int2str(obj.component_chain{i,j}.chain_id(k)),",");
                       else
                           mystr= append(mystr, "  ");
                       end
                   end
                   mystr=append(mystr, "] ");
               end
               disp(mystr)
           end
           fprintf("\n")
       end
       function chain(obj, comp_list)
           comps_remaining = comp_list;
           ch = {};
           up = {};
           chid = ComponentGraphNode.newchain(1);
           while ~(isempty(comps_remaining))
               [~, chhold, nodes_out,uphold] = obj.make_chain(comps_remaining{1},chid);
               rm_comp = false(1, numel(comps_remaining));
               for j = 1:length(comp_list)
                  comp = comp_list{j};
                  for k = 1:length(nodes_out)
                     node = nodes_out{k};
                     if node.comp_handle == comp
                        rm_comp(k) = true;
                     end
                  end
               end
               comps_remaining(rm_comp) = [];
               if ~(isempty(comps_remaining))
                  warning("There are disconnected chains in the Component structure.");
               end
               sizech = size(chhold);
               cols = size(ch,2);
               ch(1:sizech(1),cols+1:cols+sizech(2)) = chhold; 
               up = [up, uphold];
               chid = ComponentGraphNode.newchain();
           end
           obj.component_chain = ch;
           obj.update_order = up;
           disp(up);
       end
   end
   methods(Static)
       function update_order = chain_update_order(root)
           % remove duplicates and return
       end
       function [rootrow, chain, comp_chained, update_order] = make_chain(root_comp, chain_id, dir)
           % the chain is a NxM cell array where N is the total graph
           % height and M is the maximum graph width
           % Each cell contains a struct with a .chain_id array,
           % a .comp_handle component handle,
           % and a .update_order
           persistent exclude_list
           if nargin < 3
              exclude_list = {};
              dir = ComponentGraph.Neither; % initially not inlet or outlet
           end
           this_node = ComponentGraphNode(root_comp, chain_id);
           chain = {this_node};
           update_order = {root_comp};
           rootrow = 1; % row of the root comp in the output chain array - always in first column
           exclude_list{end+1} = (this_node); % handling this root now - don't check it ever again          
           for i = 0:1
               if i == 0
                   comp_list = root_comp.inlet;
                   new_dir = ComponentGraph.Inlet;
               else
                   comp_list = root_comp.outlet;
                   new_dir = ComponentGraph.Outlet;
               end
               first_chain = length(exclude_list)==1 || (dir==new_dir);
               for j = 1:length(comp_list) % for each component
                   comp = comp_list{j};
                   exclude = [];
                   for k = 1:length(exclude_list) % check excluded components
                       exclude_node = exclude_list{k};
                       if comp == exclude_node.comp_handle % found this node in the exclude chain!
                          exclude = exclude_node.chain_id;
                          if ~any(ismember(exclude,this_node.chain_id),'all') || new_dir == dir % if the two are connected circularly, connect them with a warning!
                               warning("Circular relationship found in component tree. Default update order may not perform as expected.");
                               new_id = ComponentGraphNode.newchain();
                               this_node.chain_id(end+1)= new_id;
                               exclude_node.chain_id(end+1) = new_id;
                          end
                          break
                       end
                   end
                   if ~isempty(exclude)
                       continue;
                   end
                   if first_chain 
                       % If branching down (new_dir = outlet) and came from an inlet (dir = inlet), always make new chain
                       % Otherwise, if its the first chain we've made from
                       % this root, continue the same chain id
                       [rootrowx,chainx,~,update_orderx] = ComponentGraph.make_chain(comp, chain_id, new_dir);
                   else
                        new_chainid = ComponentGraphNode.newchain();
                        this_node.chain_id(end+1) = new_chainid;
                        [rootrowx,chainx,~,update_orderx] = ComponentGraph.make_chain(comp, new_chainid, new_dir);
                        % add to RHS of cell array
                   end
                   % Assemble resulting chain array
                   chainsize = size(chain);
                   chainxsize = size(chainx);
                   if new_dir == ComponentGraph.Inlet %if collected an upstream chain
                       if first_chain
                           chainx(rootrowx+1:rootrowx+chainsize(1),1:chainsize(2)) = chain;
                       else
                           chainx(rootrowx+1:rootrowx+chainsize(1),1+chainxsize(2):chainxsize(2)+chainsize(2)) = chain;
                       end
                       rootrow = rootrowx+1;
                       chain = chainx;
                       update_order = [update_orderx update_order];
                   else
                       if first_chain
                           chain(rootrow+1:rootrow+chainxsize(1),chainsize(2):chainsize(2)+chainxsize(2)-1) = chainx;
                       else
                           chain(rootrow+1:rootrow+chainxsize(1),1+chainsize(2):chainsize(2)+chainxsize(2)) = chainx;
                       end
                       update_order = [update_order update_orderx];
                   end
                   if first_chain
                      first_chain = false; 
                   end
               end
               comp_chained = exclude_list;
           end
       end
       
   end
end