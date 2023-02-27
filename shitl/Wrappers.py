import asyncio
import matlab.engine
from .SlateClient import SlateClient

class Simulation:
    UPDATE_TIME = 1
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

    def update(self):
        for handler in self.handlers:
            handler()

    def update_handlers(self):
        self.handlers = [lambda: self.slate.set_field(channel, self.eng.eval(channel), forward=False) for channel in self.slate.metaslate["channels"] if self.name in channel]
    
class Valve:
    def __init__(self, name, inlet, outlet, engine):
        self.name = name
        self.eng = engine
        self.inlet = inlet
        self.outlet = outlet
        self.value = -1

    def update(self, slate):
        if self.name in slate and slate[self.name] != self.value:
            self.value = slate[self.name]
            self.attach() if self.value else self.detach()

    def attach(self):
        self.eng(self.name + ".attach_inlet_to({})".format(self.inlet.name))
        self.eng(self.name + ".attach_outlet_to({})".format(self.outlet.name))

    def detach(self):
        self.eng(self.name + ".detach_inlets()")
        self.eng(self.name + ".detach_outlets()")