module erspy::utils;

import erspy::packet;

import std::collections::list;
import std::collections::map;
import nt_ext;
import roblox;

struct CapturedPacket {
    Packet raw;
    List{CapturedArg} args;
    String encoded_args;
    usz timestamp;
}

struct CapturedArg {
    TTypeId type;
    Variant data;
    String display;
}

struct RemoteEntry {
    EventType type;
    uptr instance;
    String name;
    String path;
    List{CapturedPacket} history;
}

fn void RemoteEntry.free(&self, Allocator allocator) {
    self.name.free(allocator);
    self.path.free(allocator);

    foreach (packet : self.history) {
        packet.encoded_args.free(allocator);

        foreach (arg : packet.args) arg.display.free(allocator);
        packet.args.free();
    }

    self.history.free();
}

// --- common ---

fn RemoteEntry*? alloc_remote_entry(RemoteSpy* spy, EventType type, uptr instance) {
    InstanceEx remote;
    remote.init(spy.allocator, spy.client.memory, instance)!;

    String name = remote.get_name() ?? ("Unnamed").copy(spy.allocator);
    String path = remote.get_full_name() ?? ("Unknown").copy(spy.allocator);

    RemoteEntry* entry = allocator::alloc(spy.allocator, RemoteEntry);
    entry.type = type;
    entry.instance = instance;
    entry.name = name;
    entry.path = path;
    entry.history.init(spy.allocator);

    return entry;
}
