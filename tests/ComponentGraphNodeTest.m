%% Linear Node Test
clear all;
sim = Simulation();
node1 = SimpleNode();
node2 = SimpleNode();
node3 = SimpleNode();
node1.attach_outlet_to(node2);
assert(node2.inlet{1}==node1 && node1.outlet{1} == node2);
node3.attach_inlet_to(node2);
assert(node3.inlet{1}==node2 && node2.outlet{1}==node3);
disp(sim);
for i = 1:length(sim.comp_graph.update_order)
    comp = sim.comp_graph.update_order{i};
    comp.update(); 
end

%% Branching Node Test
clear all;
sim = Simulation();
node1 = SimpleNode();
node2 = SimpleNode();
node3 = SimpleNode();
node4 = SimpleNode();
node5 = SimpleNode();
node6 = SimpleNode();
node7 = SimpleNode();
node8 = SimpleNode();

node1.attach_outlet_to(node2);
node3.attach_inlet_to(node2);
node4.attach_outlet_to(node2);
node5.attach_inlet_to(node2);
node6.attach_inlet_to(node5);
node7.attach_outlet_to(node4);
node8.attach_inlet_to(node7);
disp(sim);
for i = 1:length(sim.comp_graph.update_order)
    comp = sim.comp_graph.update_order{i};
    comp.update(); 
end

%% Separated Trees Node Test
clear all;
sim = Simulation();
node1 = SimpleNode();
node2 = SimpleNode();
node3 = SimpleNode();
node4 = SimpleNode();
node5 = SimpleNode();

node1.attach_outlet_to(node2);
node3.attach_inlet_to(node2);
node4.attach_outlet_to(node5);
disp(sim);
for i = 1:length(sim.comp_graph.update_order)
    comp = sim.comp_graph.update_order{i};
    comp.update(); 
end

%% Circular Tree Node Test
clear all;
sim = Simulation();
node1 = SimpleNode();
node2 = SimpleNode();
node3 = SimpleNode();
node4 = SimpleNode();

node1.attach_outlet_to(node2);
node3.attach_inlet_to(node2);
node3.attach_outlet_to(node1);
node3.attach_outlet_to(node4);
disp(sim);
for i = 1:length(sim.comp_graph.update_order)
    comp = sim.comp_graph.update_order{i};
    comp.update(); 
end