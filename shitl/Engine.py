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
            Valve("orifice", self.tanks[0], self.tanks[1], Engine.MATLAB, self.slate)
        ]

        for tank in self.tanks:
            tank.update_handlers()
        for valve in self.valves:
            valve.update_handlers()

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
            self.sim.run()
            for tank in self.tanks:
                await tank.update()
            await asyncio.sleep(Simulation.UPDATE_TIME)

    async def update(self):
        while True:
            slate = await self.slate.recv_slate()
            try:
                for valve in self.valves:
                    valve.update(slate)
            except Exception as e:
                print("Failure while updating valves", e)
