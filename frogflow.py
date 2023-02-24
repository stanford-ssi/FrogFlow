import asyncio
from aiohttp import web

import matlab.engine

from shitl.AudubonClient import AudubonClient
from shitl.Engine import Engine

class Server:
    def __init__(self):
        self.app = web.Application()
        self.app.on_startup.append(self.startup)
        
        self.history = {}
        self.quail_tx_queue = asyncio.Queue()

        self.audubon = None
        self.engine = None

    def start(self):
        web.run_app(self.app, port=8081)

    async def startup(self, app):
        self.audubon = AudubonClient('192.168.2.2', 1002, '192.168.2.3', 1002)
        await self.audubon.connect()
        self.app.forward_to_quail = asyncio.create_task(self.audubon.to_quail())
        # await self.audubon.slates['telemetry'].recv_slate() # set up is done
        # self.app.quail_rx_task = asyncio.create_task(self.quail_rx_task())
        # self.app.quail_tx_task = asyncio.create_task(self.quail_tx_task())
        # self.engine = Engine(self.audubon.slates["telemetry"])
        # self.app.sensors = asyncio.create_task(self.engine.run())
        # self.app.actuators = asyncio.create_task(self.engine.update())

    async def quail_rx_task(self):
        while (True):
            slate = await self.audubon.slates['telemetry'].recv_slate()
            for valve in self.valves:
                valve.update(slate)

    async def quail_tx_task(self):
        while(True):
            path, value = await self.quail_tx_queue.get()
            print(f"Setting {path} to {value}")
            path = path.split(".")
            assert path[0] == "quail"
            await self.audubon.slates[path[1]].set_field(path[2], value) # does this break booleans? smh
            self.quail_tx_queue.task_done() 

if __name__ == "__main__":
    page = Server()
    page.start()