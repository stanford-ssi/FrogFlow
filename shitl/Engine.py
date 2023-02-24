import asyncio
import matlab.engine
from shitl.Wrappers import *

class Engine:
    def __init__(self, slate):
        self.slate = slate

        self.eng = matlab.engine.start_matlab()
        self.eng.Olympus(nargout=0)

        self.tanks = [
            Tank("tank", self.eng, self.slate),
            Tank("ambient", self.eng, self.slate)
        ]
        self.valves = [
            Valve("orifice", self.tanks[0], self.tanks[1], self.eng)
        ]

        self.sim = Simulation("sim", self.eng)

    async def run(self):
        while True:
            self.sim.run()
            for tank in self.tanks:
                tank.update()
            await asyncio.sleep(Simulation.UPDATE_TIME)

    async def update(self):
        while True:
            slate = await self.slate.recv_slate()
            for valve in self.valves:
                valve.update(slate)