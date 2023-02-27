import asyncio
from aiohttp import web

import matlab.engine

from shitl.AudubonClient import AudubonClient
from shitl.Engine import Engine

class Server:
    def __init__(self):
        self.app = web.Application()
        self.app.on_startup.append(self.startup)
        self.app.on_cleanup.append(self.cleanup_background_tasks)
        
        self.history = {}
        self.quail_tx_queue = asyncio.Queue()

        self.audubon = None
        self.engine = None

    def start(self):
        web.run_app(self.app, port=8081)

    async def startup(self, app):
        Engine.init_matlab() # takes long and messes up networking if not first
        self.audubon = AudubonClient(('192.168.2.2', 1002), ('127.0.0.1', 9999))
        await self.audubon.connect()
        self.app.forward_to_quail = asyncio.create_task(self.audubon.to_quail())
        self.app.forward_from_quail = asyncio.create_task(self.audubon.from_quail())
        await self.audubon.ready() # set up is done
        # self.app.quail_rx_task = asyncio.create_task(self.quail_rx_task())
        self.engine = Engine(self.audubon.slates['telemetry'])
        self.app.quail_tx_task = asyncio.create_task(self.quail_tx_task())
        self.app.sensors = asyncio.create_task(self.engine.run())
        self.app.actuators = asyncio.create_task(self.engine.update())

    async def quail_rx_task(self):
        while (True):
            slate = await self.audubon.slates['telemetry'].recv_slate()
            for valve in self.engine.valves:
                valve.update(slate)

    async def quail_tx_task(self):
        while(True):
            path, value = await self.quail_tx_queue.get()
            print(f"Setting {path} to {value}")
            path = path.split(".")
            assert path[0] == "quail"
            await self.audubon.slates[path[1]].set_field(path[2], value) # does this break booleans? smh
            self.quail_tx_queue.task_done() 

    async def cleanup_background_tasks(self, app):
        self.app.forward_to_quail.cancel()
        self.app.forward_from_quail.cancel()
        # self.app.quail_rx_task.cancel()
        self.app.quail_tx_task.cancel()
        self.app.sensors.cancel()
        self.app.actuators.cancel()

        await self.app.forward_to_quail
        await self.app.forward_from_quail
        await self.app.quail_rx_task
        await self.app.quail_tx_task
        await self.app.sensors
        await self.app.actuators

if __name__ == "__main__":
    page = Server()
    page.start()