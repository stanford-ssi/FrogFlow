classdef SurfaceConvection < Conduit
    % Natural convection node for use with a Surface object. The other end
    % of this conduit can be connected to any node type containing a fluid.
    % If the connected node's fluid is a Gas, the concept of a vapor film
    % is applied, and the Gas's state is temporarily updated to the mean
    % temperature between the Gas and Surface for fluid properties.
    % If connected to a Tank, ensure to connect at the appropriate height.
    % The area and length inputs are pulled from the Surface object.
    properties
        c; % empirical Nusselt number correlation w/ Rayleigh number, Nu = c*(Ra)^n
        n; % empirical Nusselt number correlation w/ Rayleigh number, Nu = c*(Ra)^n
        E; % empirical multiplicative factor (Qdot_sim = E*Qdot_analytical)
    end
    methods
        function obj = SurfaceConvection(c,n,E,child_conduit)
            if nargin < 2
                E = 1;
            end
            if nargin < 3
                child_conduit = false;
            end
            obj@Conduit(child_conduit);
            obj.c = c;
            obj.n = n;
            obj.E = E;
        end
        function [mdot, Udot] = flowdot(obj)
            if isa(obj.inlet,'Surface')
                surfside = obj.inlet;
                fluidside = obj.outlet.get_fluid(obj.outlet_height);
                dir = 1; 
            else
                surfside = obj.outlet;
                fluidside = obj.inlet.get_fluid(obj.inlet_height);
                dir = -1;
            end
            Thold = -1;
            Tsurf = surfside.T; % temp of surfacce
            if isa(fluidside,'Gas')
                % Fluid is Gas, apply vapor film
                Thold = fluidside.T; % temp of fluid
                fluidside.update_PT(fluidside.P,0.5*(Thold+Tsurf))
            end
            Tfluid = fluidside.T;
            dT = Tsurf - Tfluid;
            Ra = fluidside.cp*(fluidside.rho^2)*(Component.sim.accel)*fluidside.beta ...
                    *abs(dT)*(surfside.length^3)/(fluidside.mu*fluidside.k);
            Nu = obj.c*(Ra^obj.n);
            h = Nu*fluidside.k/surfside.length;
            if Thold < 0
                % Updated the fluid state for the purpose of vapor film
                fluidside.update_PT(fluidside.P,Thold)
            end
            mdot = 0;
            Udot = dir*h*surfside.area*dT;
        end
    end
end