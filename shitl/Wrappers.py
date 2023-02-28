import asyncio
import matlab.engine
from .SlateClient import SlateClient

class Simulation:
    UPDATE_TIME = 2
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

    async def update(self):
        for handler in self.handlers:
            await handler()

    def update_handlers(self):
        self.handlers = []
        for channel, fields in self.slate.metaslate['channels'].items():
            matlab_cmd = fields['matlab'] if 'matlab' in fields else ""
            if matlab_cmd.split('.')[0] == self.name:
                self.handlers += [lambda: self.slate.set_field(channel, self.eng.eval(matlab_cmd)[-1][0], forward=False)]
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
        self.eng(self.inlet.name + ".attach_outlet_to({}, 0);".format(self.name), nargout=0)
        self.eng(self.outlet.name + ".attach_inlet_to({});".format(self.name), nargout=0)

    def detach(self):
        self.eng(self.name + ".detach_inlets();", nargout=0)
        self.eng(self.name + ".detach_outlets();", nargout=0)