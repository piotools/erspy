module roblox::client;

import std::io;
import std::collections::list;
import winapi;
import nt_ext;

const String PROCESS_NAME @private = "RobloxPlayerBeta.exe";

struct Client {
    Allocator allocator;
    Memory* memory;
    CaveRemote* remote;
    uptr base_address;
}

fn void? Client.init(&self, Allocator allocator, uint process_id, bool should_hijack = true) {
    Memory* memory = allocator::new(allocator, Memory);
    CaveRemote* remote = allocator::new(allocator, CaveRemote);

    if (should_hijack) {
        memory.process_id = process_id;
        memory.process_handle = handle::hijack_process(process_id, winapi::PROCESS_ALL_ACCESS)!;
        memory.peb = memory.get_peb()!;
    } else {
        memory.open(process_id, winapi::PROCESS_ALL_ACCESS)!;
    }

    remote.init(allocator, memory)!;

    self.allocator = allocator;
    self.memory = memory;
    self.remote = remote;
    self.base_address = memory.get_base_address();
}

fn void? Client.deinit(&self) {
    if (self.remote) {
        self.remote.deinit()!;
        allocator::free(self.allocator, self.remote);
        self.remote = null;
    }

    if (self.memory) {
        self.memory.close();
        allocator::free(self.allocator, self.memory);
        self.memory = null;
    }
}

fn uint Client.get_process_id(&self) @inline => self.memory.process_id;
fn void* Client.get_process_handle(&self) @inline => self.memory.process_handle;

// --- common ---

fn Client*? first(Allocator allocator) {
    uint process_id = process::find_process_id(PROCESS_NAME)!;

    Client* client = allocator::new(allocator, Client);
    client.init(allocator, process_id)!;

    return client;
}

fn List{uint}? get_client_pids(Allocator allocator) {
    List{uint} process_ids;
    process_ids.init(allocator);

    ProcessIterator iterator;
    iterator.init(allocator)!;
    defer iterator.free();

    while (try entry = iterator.next()) {
        if (entry.image_name.buffer && entry.image_name == PROCESS_NAME) {
            process_ids.push((uint)(uptr)entry.unique_process_id);
        }
    }

    return process_ids;
}
