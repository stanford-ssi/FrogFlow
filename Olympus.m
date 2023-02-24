clear all
close all
clc
addpath(genpath("ref/"),genpath("lib/"),genpath("tests/"));

Ptank = 550*6894.76; % high enough to be initially choked
Ttank = 298; % room temp
Vtank = 3.95E-3; 
Vliq = 1.9E-3;
Dtank = 5*0.0254; % diameter
Pambient = 12.7*6894.76; % atmospheric pressure
Tambient = 298; % ambient temp

A = 1.8E-6; % 1 mm^2 = 1E-6 m^2
Cd = 1.0; 

sim = Simulation();
tank = SPITank(IdealNitrogen(Ptank,Ttank),Water(Ptank,Ttank),Vtank,Vliq,pi/4*(Dtank^2));
ambient = InfiniteVolume(IdealNitrogen(Pambient,Tambient));
orifice = Orifice(Cd,A);

tank.attach_outlet_to(orifice,0);
ambient.attach_inlet_to(orifice);