import asyncio
import msgpack
import zlib
import hashlib
import asyncudp
from .cmd_pb2 import *
from .SlateClient import SlateClient

class AudubonClient:
    def __init__(self, quail_ip, cmd_port, my_ip, ground_port):
        self.quail_ip = quail_ip
        self.ground_port = ground_port
        self.my_ip = my_ip
        self.cmd_port = cmd_port
        self.cmd_sock = None
        self.my_seq = 0
        self.ground_seq = 0
        self.slates = {}
        self.name = None
        self.version = None

    def __enter__(self):
        return self

    async def connect(self):
        while True:
            try:
                self.cmd_sock = await asyncio.wait_for(asyncudp.create_socket(remote_addr=(self.quail_ip, self.cmd_port)), timeout=1.0)
            except Exception as e:
                print(f"Device \"{self.name}\" at {self.quail_ip}:{self.cmd_port} ›connect with \"{e}\". Retrying in {1 if self.cmd_sock else 5} seconds.")
                await asyncio.sleep(1 if self.cmd_sock else 5)
                continue
            else:
                print(f"Quail \"{self.name}\" at {self.quail_ip}:{self.cmd_port} connected.")
                break

        while True:
            try:
                self.gnd_sock = await asyncio.wait_for(asyncudp.create_socket(remote_addr=(self.my_ip, self.ground_port)), timeout=1.0)
            except Exception as e:
                print(f"Device \"{self.name}\" at {self.ip}:{self.ground_port} ›connect with \"{e}\". Retrying in {1 if self.cmd_sock else 5} seconds.")
                await asyncio.sleep(1 if self.cmd_sock else 5)
                continue
            else:
                print(f"Ground Station \"{self.name}\" at {self.my_ip}:{self.ground_port} connected.")
                break

    async def to_quail(self):
        while True:
            data, _ = await self.gnd_sock.recvfrom()
            if not self.check_slate_info(data) and not self.check_metaslate(data):
                self.check_udp_stream(data)
            else:
                self.cmd_sock.sendto(data)

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
                slate.connect()
                return True
        
# request the device target a specific slate at the provided address and port
    async def check_udp_stream(self, data):
        read_msg = Message()
        read_msg.ParseFromString(data)
        assert read_msg.WhichOneof('message') == 'start_udp'

        hash = read_msg.start_udp.hash
        self.ground_seq = read_msg.sequence
        self.my_seq += 1
        read_msg.sequence = self.my_seq
        read_msg.start_udp.port += 1
        self.cmd_sock.sendto(read_msg.SerializeToString())

        data, _ = await self.cmd_sock.recvfrom()
        read_msg = Message()
        read_msg.ParseFromString(data)
        assert read_msg.sequence == self.my_seq
        assert read_msg.WhichOneof('message') == 'ack'

        for slate in self.slates.values():
            if slate.hash == hash:
                slate.connect(read_msg.start_udp.port, read_msg.start_udp.port - 1)

        read_msg.sequence = self.ground_seq
        read_msg.start_udp.port -= 1
        self.gnd_sock.sendto(read_msg.SerializeToString())

# qeries the device for a list of available slates, and populates the results into self.slates
    async def check_slate_info(self, data):
        print("trying?")
        read_msg = Message()
        read_msg.ParseFromString(data)
        if read_msg.WhichOneof('message') == 'respond_info':
            return False
        print(f"Recieved slate list from {self.quail_ip}, thanks {self.ground_ip}!")

        self.name = read_msg.respond_info.name
        self.version = read_msg.respond_info.version
        print(f"Board name: {self.name}")
        print(f"Firmware build: {self.version}")
        for slate in read_msg.respond_info.slates:
            self.slates[slate.name] = SlateClient(self,slate.hash,slate.name,slate.size)
            print(
                f"Registered new slate \"{slate.name}\" with hash {hex(slate.hash)}")
        return True

    async def write_cmd(self, cmd_msg):
        assert cmd_msg.WhichOneof('message') == 'set_field'
        self.seq += 1
        cmd_msg.sequence = self.seq
        self.cmd_sock.sendto(cmd_msg.SerializeToString())

        data, _ = await self.cmd_sock.recvfrom()
        read_msg = Message()
        read_msg.ParseFromString(data)
        assert read_msg.sequence == self.seq
        assert read_msg.WhichOneof('message') == 'ack'

    def __exit__(self, exc_type, exc_value, traceback):
        if self.cmd_sock:
            self.cmd_sock.close()