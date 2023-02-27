import asyncio
import matlab.engine
from shitl.Wrappers import *

class Engine:
    MATLAB = None

    def __init__(self, slate):
        self.slate = slate

        Engine.init_matlab()

        self.tanks = [
            Tank("tank", Engine.MATLAB, self.slate),
            Tank("ambient", Engine.MATLAB, self.slate)
        ]
        self.valves = [
            Valve("orifice", self.tanks[0], self.tanks[1], self.MATLAB)
        ]

        self.sim = Simulation("sim", self.MATLAB)

    @classmethod
    def init_matlab(cls):
        if Engine.MATLAB == None:
            print("Starting Matlab Engine")
            Engine.MATLAB = matlab.engine.start_matlab()
            Engine.MATLAB.Olympus(nargout=0)
            print("Engine Started - Let's Boogy")

    async def run(self):
        while True:
            print("Simulation updating...")
            self.sim.run()
            for tank in self.tanks:
                tank.update()
            await asyncio.sleep(Simulation.UPDATE_TIME)

    async def update(self):
        while True:
            slate = await self.slate.recv_slate()
            for valve in self.valves:
                valve.update(slate)