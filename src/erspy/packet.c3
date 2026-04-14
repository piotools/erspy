module erspy::packet;

import std::atomic;
import nt_ext, msvc_ext;
import roblox;

faultdef PACKETS_EMPTY, ARGUMENTS_EMPTY;

enum EventType {
    RELIABLE, // RemoteEvent
    UNRELIABLE, // UnreliableRemoteEvent
    FUNCTION // RemoteFunction
}

struct Packet {
    EventType type;
    Instance* remote;
    SharedPtr{Tuple} args;
    uptr original_cb;
}

struct PacketBuffer {
    Atomic{usz} written;
    Atomic{usz} read;
    Packet[erspy::MAX_PACKETS] data;
}

fn TupleEx? Packet.get_args(&self, Allocator allocator, Memory* memory) {
    if (!self.args.ptr) return ARGUMENTS_EMPTY~;

    TupleEx args;
    args.init(allocator, memory, (uptr)self.args.ptr)!;

    return args;
}

fn String? Packet.get_encoded_args(&self, Allocator allocator, Memory* memory) {
    if (!self.args.ptr) return ("{}").copy(allocator);

    TupleEx args;
    args.init(allocator, memory, (uptr)self.args.ptr)!;
    defer args.free();

    return args.to_string(allocator);
}

fn void PacketBuffer.push(&self, Packet packet) @inline {
    usz written = self.written.load(RELAXED);
    usz read = self.read.load(ACQUIRE);

    if (written - read >= self.data.len) return;

    self.data[written % self.data.len] = packet;
    self.written.store(written + 1, RELEASE);
}

fn Packet? PacketBuffer.pop(&self) {
    usz read = self.read.load(RELAXED);
    usz written = self.written.load(ACQUIRE);

    if (read == written) return PACKETS_EMPTY~;

    Packet packet = self.data[read % self.data.len];
    self.read.store(read + 1, RELEASE);

    return packet;
}
