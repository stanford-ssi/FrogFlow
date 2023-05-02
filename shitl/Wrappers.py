import asyncio
import matlab.engine
from .SlateClient import SlateClient
import numpy as np

class Simulation:
    UPDATE_TIME = 25
    def __init__(self, name, engine):
        self.name = name
        self.eng = engine
        self.curr_time = 0

    def get_time(self):
        return self.eng.eval(self.name + ".time")
    
    def run(self):
        self.eng.eval(self.name + ".run([{} {}]);".format(
                self.curr_time,
                self.curr_time + Simulation.UPDATE_TIME
        ), nargout=0)
        self.curr_time += Simulation.UPDATE_TIME

class Tank:
    def __init__(self, name, engine, slate):
        self.name = name
        self.eng = engine
        self.slate = slate
        self.handlers = []
        self.cmd = ""

    async def update(self):
        channel, matlab_cmd = self.cmd
        vals = np.array(self.eng.eval(matlab_cmd))[:,0]
        for val in vals:
            await self.slate.set_field(channel, val, forward=False)
            await asyncio.sleep(Simulation.UPDATE_TIME / len(vals))


    def update_handlers(self):
        self.handlers = []
        for channel, fields in self.slate.metaslate['channels'].items():
            matlab_cmd = fields['matlab'] if 'matlab' in fields else ""
            if matlab_cmd.split('.')[0] == self.name:
                self.cmd = (channel, matlab_cmd)
                return

class Valve:
    def __init__(self, name, inlet, outlet, engine, slate):
        self.name = name
        self.slate_key = ""
        self.eng = engine
        self.inlet = inlet
        self.outlet = outlet
        self.value = 1
        self.slate = slate

    def update_handlers(self):
        for channel, fields in self.slate.metaslate['channels'].items():
            matlab_name = fields['matlab'] if 'matlab' in fields else ""
            if matlab_name == self.name:
                self.slate_key = channel
                return

    def update(self, telemetry):
        telem_value = telemetry[self.slate_key] if self.slate_key in telemetry else self.value
        if telem_value != self.value:
            self.value = telem_value
            self.attach() if self.value else self.detach()

    def attach(self):
        self.eng.eval("{}.attach_outlet_to({}, 0);".format(self.inlet.name, self.name), nargout=0)
        self.eng.eval("{}.attach_inlet_to({});".format(self.outlet.name, self.name), nargout=0)

    def detach(self):
        self.eng.eval("{}.detach_outlets();".format(self.inlet.name), nargout=0)
        self.eng.eval("{}.detach_inlets();".format(self.outlet.name), nargout=0)