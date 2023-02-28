import asyncio
import msgpack
import zlib
import hashlib
import asyncudp
from .cmd_pb2 import *
from .SlateClient import SlateClient

class AudubonClient:
    def __init__(self, quail_addr, gnd_addr):
        self.quail_addr = quail_addr
        self.gnd_addr = gnd_addr
        self.cmd_sock = None
        self.slates = {}
        self.seq = 1 # offset to avoid clash
        self.gnd_seq = 0 
        self.name = None
        self.version = None
        self.no_forward = asyncio.Queue()
        self.setup_telemtry = asyncio.Queue()

    def __enter__(self):
        return self

    async def connect(self):
        while True:
            try:
                self.cmd_sock = await asyncio.wait_for(asyncudp.create_socket(remote_addr=self.quail_addr), timeout=1.0)
            except Exception as e:
                print(f"Device \"{self.name}\" at {self.quail_addr[0]}:{self.quail_addr[1]} ›connect with \"{e}\". Retrying in {1 if self.cmd_sock else 5} seconds.")
                await asyncio.sleep(1 if self.cmd_sock else 5)
                continue
            else:
                print(f"Quail at {self.quail_addr[0]}:{self.quail_addr[1]} connected.")
                break

        while True:
            try:
                self.gnd_sock = await asyncio.wait_for(asyncudp.create_socket(local_addr=self.gnd_addr), timeout=1.0)
            except Exception as e:
                print(f"Device \"{self.name}\" at {self.gnd_addr[0]}:{self.gnd_addr[1]} ›connect with \"{e}\". Retrying in {1 if self.cmd_sock else 5} seconds.")
                await asyncio.sleep(1 if self.cmd_sock else 5)
                continue
            else:
                print(f"Ground Station at {self.gnd_addr[0]}:{self.gnd_addr[1]} connected.")
                break

    async def from_quail(self):
        while True:
            data, _ = await self.cmd_sock.recvfrom()

            await self.check_slate_info(data)
            await self.check_metaslate(data)
            
            msg = Message()
            msg.ParseFromString(data)
            if msg.sequence == self.seq:
                pass # this is meant for me, not ground
            elif msg.sequence == self.gnd_seq:       
                print("Intercepted from quail:", msg.WhichOneof('message'))
                self.gnd_sock.sendto(data, self.gnd_addr)

    async def to_quail(self):
        while True:
            data, addr = await self.gnd_sock.recvfrom()
            self.gnd_addr = addr
                
            msg = Message()
            msg.ParseFromString(data)
            self.gnd_seq = msg.sequence
            print("Intercepted to quail:", msg.WhichOneof('message'))

            new_data = await self.intercept_udp_stream(data)
            self.seq += 1 # Audubon seq always at least one ahead of Ground seq

            self.cmd_sock.sendto(new_data)

    async def ready(self):
        await self.setup_telemtry.get()

    async def check_metaslate(self, data):
        read_msg = Message()
        read_msg.ParseFromString(data)
        if read_msg.WhichOneof('message') != 'response_metaslate':
            return False

        check_hash = int.from_bytes(hashlib.sha256(
            read_msg.response_metaslate.metaslate).digest()[:8], 'little')
        for slate in self.slates.values():
            if slate.hash == check_hash:
                metaslate_data = zlib.decompress(read_msg.response_metaslate.metaslate)
                metaslate_data = msgpack.unpackb(metaslate_data)
                slate.metaslate = metaslate_data
                return True
        
    # request the device target a specific slate at the provided address and port
    async def intercept_udp_stream(self, data):
        read_msg = Message()
        read_msg.ParseFromString(data)
        if read_msg.WhichOneof('message') != 'start_udp':
            return data

        hash = read_msg.start_udp.hash
        port = read_msg.start_udp.port
        for slate in self.slates.values():
            if slate.hash == hash:
                await slate.connect(port)
                if slate.name == 'telemetry':
                    self.setup_telemtry.put_nowait(1)
                read_msg.start_udp.port = slate.udp_rcv_sock._transport._sock.getsockname()[1]
                return read_msg.SerializeToString()

    # qeries the device for a list of available slates, and populates the results into self.slates
    async def check_slate_info(self, data):
        read_msg = Message()
        read_msg.ParseFromString(data)
        if read_msg.WhichOneof('message') != 'respond_info':
            return False
        print(f"Recieved slate list from {self.quail_addr[0]}, thanks {self.gnd_addr[0]}:{self.gnd_addr[1]}!")

        self.name = read_msg.respond_info.name
        self.version = read_msg.respond_info.version
        print(f"Board name: {self.name}")
        print(f"Firmware build: {self.version}")
        for slate in read_msg.respond_info.slates:
            self.slates[slate.name] = SlateClient(self,slate.hash,slate.name,slate.size)
            print(
                f"Registered new slate \"{slate.name}\" with hash {hex(slate.hash)}")
        return True

    async def write_cmd(self, cmd_msg, forward=True):
        assert cmd_msg.WhichOneof('message') == 'set_field'
        if forward:
            cmd_msg.seq = self.gnd_seq
        else:
            self.seq += 1
            cmd_msg.sequence = self.seq
            self.cmd_sock.sendto(cmd_msg.SerializeToString())

    def __exit__(self, exc_type, exc_value, traceback):
        if self.cmd_sock:
            self.cmd_sock.close()