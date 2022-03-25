%% Run All Tests
addpath(genpath("ref\"),genpath("lib\"),genpath("tests\"));
results = runtests('SimpleSimulationTest','IncludeSubfolders',true);
% results = runtests(fullfile(pwd,'tests'),'IncludeSubfolders',true);