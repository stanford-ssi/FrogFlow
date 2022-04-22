classdef ComponentGraph < handle
   properties(Constant)
      Inlet = 0;
      Outlet = 1;
      Neither = 2;
   end
   methods(Static)
       function disp(component_chain)
           chain_size = size(component_chain);
           chainid_tree = cell(chain_size);
           maxlen = zeros(1,chain_size(2));
           for i = 1:chain_size(1)
               for j = 1:chain_size(2)
                   if ~isempty(component_chain{i,j})
                        chainid_tree{i,j} = component_chain{i,j}.chain_id;
                        maxlen(j) = max(maxlen(j),length(component_chain{i,j}.chain_id));
                   end
               end
           end
           for i = 1:chain_size(1)
               mystr = "";
               for j = 1:chain_size(2)
                   mystr = append(mystr, "[ ");
                   for k = 1:maxlen(j)
                       if ~isempty(component_chain{i,j}) && k <= length(component_chain{i,j}.chain_id)
                           mystr= append(mystr,sprintf("%1.2f",component_chain{i,j}.chain_id(k)),", ");
                       else
                           mystr= append(mystr, "      ");
                       end
                   end
                   mystr=append(mystr, "] ");
               end
               disp(mystr)
           end
           fprintf("\n")
       end
       function updatelist = make_updatelist(comp_list)
           comps_remaining = comp_list;
           ch = {};
           up = {};
           chid = ComponentGraphNode.newchain(1);
           while ~(isempty(comps_remaining))
              if isa(comps_remaining{1},'Node') && ~comps_remaining{1}.ischild
                   [~, chhold, compnodes_handled,uphold] = ComponentGraph.make_chain(comps_remaining{1},chid);
                   rm_comp = false(1, numel(comps_remaining));
                   for j = 1:length(comps_remaining)
                      comp = comps_remaining{j};
                      if ~isa(comp, 'Node') || comp.ischild % if is invalid type for updating (i.e. a child Node or a non-Node component)
                         rm_comp(j) = true;
                         continue;
                      end
                      for k = 1:length(compnodes_handled)
                         compnode = compnodes_handled{k};
                         if compnode.comp_handle == comp
                            rm_comp(j) = true;
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
              else
                  if numel(comps_remaining) > 1
                        comps_remaining = comps_remaining(2:end);
                  else
                        break
                  end
              end
           end
           component_chain = ch;
           update_order = up;
           uphold = [];
           for i = 1:numel(update_order)
                node = update_order{i};
                uphold = [uphold node.update_order];
           end
           [~,sortidx] = sort(uphold,'descend'); % sort by update order
           updatelist = update_order(sortidx);
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
              dir = ComponentGraph.Neither; % initially neither inlet nor outlet
           end      
           while ~isa(root_comp, 'Node')
               this_node = ComponentGraphNode(root_comp, chain_id);
               exclude_list{end+1} = (this_node); % handling this root now - don't check it ever again      
               if dir == ComponentGraph.Inlet
                   next_comp = root_comp.inlet;
               else
                   next_comp = root_comp.outlet;
               end
               if ~isempty(next_comp) % if a component actually attached in the direction of search
                   root_comp = next_comp; % iterate on this component
               else % reached end of conduit chain without finding a node
                   chain = {};
                   update_order = {};
                   rootrow = 1;
                   return
               end
           end
           this_node = ComponentGraphNode(root_comp, chain_id);
           exclude_list{end+1} = (this_node); % handling this root now - don't check it ever again   
           chain = {this_node};
           update_order = {root_comp};
           rootrow = 1; % row of the root comp in the output chain array - always in first column
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
                          chain_overlap = ismember(floor(exclude),floor(this_node.chain_id));
                          if any(chain_overlap) && new_dir == dir % if the two are connected circularly, give a warning!
                               warning("Circular relationship found in component tree. Default update order may not perform as expected.");
                          end
                          if new_dir == dir % the two are connected but this isn't just the last node, create a new id for them to share
                               new_id = ComponentGraphNode.newchain();
                               if new_dir == ComponentGraph.Inlet
                                    this_node.chain_id(end+1)= new_id + 0.01;
                                    exclude_node.chain_id(end+1) = new_id;
                               else
                                    this_node.chain_id(end+1)= new_id;
                                    exclude_node.chain_id(end+1) = new_id + 0.01; 
                               end     
                          end
                          break
                       end
                   end
                   if ~isempty(exclude)
                       continue;
                   end
                   if first_chain 
                       % If this is the first chain from this node, continue it
                       if new_dir == ComponentGraph.Inlet
                            [rootrowx,chainx,~,update_orderx] = ComponentGraph.make_chain(comp, chain_id, new_dir);
                            this_node.chain_id(1) = chainx{rootrowx,1}.chain_id(1) + 0.01; %update to get chain order
                       else
                            [rootrowx,chainx,~,update_orderx] = ComponentGraph.make_chain(comp, chain_id+0.01, new_dir);
                       end
                   else
                        new_chainid = ComponentGraphNode.newchain();
                        if new_dir == ComponentGraph.Inlet
                            this_node.chain_id(end+1) = new_chainid;
                            hold_ind = length(this_node.chain_id);
                            [rootrowx,chainx,~,update_orderx] = ComponentGraph.make_chain(comp, new_chainid, new_dir);
                            this_node.chain_id(hold_ind) = chainx{rootrowx,1}.chain_id(1) + 0.01; % update to get chain order
                        else
                            this_node.chain_id(end+1) = new_chainid;
                            [rootrowx,chainx,~,update_orderx] = ComponentGraph.make_chain(comp, new_chainid+0.01, new_dir);
                        end
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
                       update_order = [update_orderx update_order]; % use row offset to make this smarter
                   else
                       if first_chain
                           chain(rootrow+1:rootrow+chainxsize(1),chainsize(2):chainsize(2)+chainxsize(2)-1) = chainx;
                       else
                           chain(rootrow+1:rootrow+chainxsize(1),1+chainsize(2):chainsize(2)+chainxsize(2)) = chainx;
                       end
                       update_order = [update_order update_orderx]; % use row offset to make this smarter
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