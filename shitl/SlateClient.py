import asyncudp
import asyncio
import struct
from .cmd_pb2 import *

class SlateClient:
    def __init__(self, audubon, slate_hash, slate_name, slate_size):
        self.audubon = audubon
        self.hash = slate_hash
        self.name = slate_name
        self.size = slate_size
        self.metaslate = None
        self.udp_rcv_sock = None
        self.udp_snd_sock = None

    async def connect(self, quail_port, gnd_port):
        try:
            self.udp_rcv_sock = await asyncudp.create_socket(remote_addr=('0', quail_port))
            self.udp_snd_sock = await asyncudp.create_socket(remote_addr=('0', gnd_port))
        except Exception as e:
            print(f"Slate \"{self.audubon.name}.{self.name}\" Disconnected")
        else:
            print(f"Slate \"{self.audubon.name}.{self.name}\" Connected")

    async def recv_slate(self):
        while True:
            try:
                recv = await asyncio.wait_for(self.udp_rcv_sock.recvfrom(), timeout=1.0)
                message, _ = recv
                self.udp_snd_sock(message)
            except Exception as e:
                await self.connect()
                continue

            slate = {}
            for name, el in self.metaslate["channels"].items():
                if el["type"] == "int16_t":
                    slate[name] = int.from_bytes(
                        message[el["offset"]:el["offset"]+el["size"]], "little", signed=True)
                elif el["type"] == "uint32_t":
                    slate[name] = int.from_bytes(
                        message[el["offset"]:el["offset"]+el["size"]], "little", signed=False)
                elif el["type"] == "bool":
                    slate[name] = (message[el["offset"]] != 0b0)
                elif el["type"] == "float":
                    slate[name] = struct.unpack('f', message[el["offset"]:el["offset"]+el["size"]])[0]

            return slate

    async def set_field(self,channel,value):
        channel_meta = self.metaslate["channels"][channel]
        msg = Message()
        msg.set_field.SetInParent()
        msg.set_field.hash = self.hash
        msg.set_field.offset = channel_meta["offset"]

        if channel_meta["type"] == "int16_t":
            msg.set_field.data_int16 = int(value)
        elif channel_meta["type"] == "bool":
            msg.set_field.data_bool = int(value)
        elif channel_meta["type"] == "uint32_t":
            msg.set_field.data_uint32 = int(value)
        elif channel_meta["type"] == "float":
            msg.set_field.data_float = float(value)
        else:
            print("don't know how to write!")

        try:
            await asyncio.wait_for(self.audubon.write_cmd(msg), timeout=1.0)
        except Exception as e:
            print(repr(e))
            print('Failed to Send')