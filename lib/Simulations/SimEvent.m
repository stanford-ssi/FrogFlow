classdef SimEvent < handle
    properties
        t = -1; % if occurred, simulation time at which it occurred (only set for CONTINUE type events)
        name; % name of this event
        msg; % msg displayed when this event is marked as occurred
        type; % type of event: CONTINUE, END, or PASS
    end
    properties(Access = private)
        triggered = false; % has this event had trigger() called since last integration run?
        occurred_x = false;
        recording = false;
    end
    properties(Constant,Hidden)
        CONTINUE = 0; % stop the simulation, mark this event as occurred, and then continue simulating
        END = 1; % stop the simulation, mark this event as occurred
        PASS = 2; % mark this event as occurred

        eventlist = DataHandle();
    end
    methods
        function obj = SimEvent(type,name,msg)
            obj@handle();
            obj.name = name;
            obj.type = type;
            obj.msg = msg;
            SimEvent.add_event(obj);
        end
        function oc = occurred(obj, t)
            if obj.occurred_x && obj.recording % event has occurred and we're recording, check time input
                oc = t > obj.t;
            else 
                oc = obj.occurred_x;
            end
        end
        function trigger(obj,t)
            if obj.recording
                return % don't trigger if recording
            end
            obj.triggered = true;
            if nargin > 1
                obj.t = t;
            end
            switch obj.type
                case SimEvent.CONTINUE
                    Component.sim.continue_sim();
                case SimEvent.END
                    Component.sim.end_sim();
                case SimEvent.PASS
                    % do nothing
            end
        end
        function update_event(obj)
            if obj.triggered
                msg_out = [obj.name,' SimEvent occurred: ',obj.msg];
                switch obj.type
                    case SimEvent.CONTINUE
                        msg_out = [msg_out '\nSimulation continuing...\n'];
                    case SimEvent.END
                        msg_out = [msg_out '\nSimulation terminated.\n'];
                    case SimEvent.PASS
                        % do nothing.
                end
                fprintf(msg_out);
                obj.occurred_x = true;
            end
            obj.triggered = false;
        end
        function record_event(obj)
            obj.recording = true;
        end
        function clear(obj)
            obj.triggered = false;
            obj.occurred_x = false;
            obj.recording = false;
            obj.t = -1;
        end
    end
    methods(Static)
        function add_event(sim_event)
            sim_event.eventlist.data = [sim_event.eventlist.data sim_event];
        end
        function update_events()
            for i = 1:length(SimEvent.eventlist.data)
                SimEvent.eventlist.data(i).update_event();
            end
        end
        function record_events()
            for i = 1:length(SimEvent.eventlist.data)
                SimEvent.eventlist.data(i).record_event();
            end
        end
        function clear_events()
            for i = 1:length(SimEvent.eventlist.data)
                SimEvent.eventlist.data(i).clear();
            end
        end
    end
end 