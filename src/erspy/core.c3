module erspy;

import logger;

import std::collections::map;
import std::thread, std::thread::threadpool;
import std::time;

import ntapi, winapi;

import nt_ext, msvc_ext;
import roblox;

faultdef CLIENT_NOT_INITIALIZED;

alias PacketHandler = fn void (RemoteSpy*, Packet*);

// --- configuration ---
const uint MAX_THREADS = 4;
const uint MAX_PACKETS = 1024 * MAX_THREADS;
const uint QUEUE_SIZE = MAX_PACKETS * MAX_THREADS;

const long PACKET_INTERVAL = -50000000; // equivalent to 5 seconds

struct RemoteSpy {
    Allocator allocator;
    Client* client;
    HookEngine engine;

    FixedThreadPool pool;
    bool is_running;

    PacketHandler on_event;
}

fn void? RemoteSpy.init(&self, Allocator allocator, uint process_id) {
    Client* client = allocator::new(allocator, Client);
    client.init(allocator, process_id)!;

    self.allocator = allocator;
    self.client = client;

    self.engine.init(allocator, client)!;
    self.engine.install_hooks()!;

    self.pool.init(MAX_THREADS, QUEUE_SIZE)!;
    self.is_running = true;

    self.spawn_exit_handler()!;
}

fn void? RemoteSpy.deinit(&self) {
    self.is_running = false;
    self.pool.stop_and_destroy()!;

    self.engine.deinit()!;

    if (self.client) {
        self.client.deinit()!;
        allocator::free(self.allocator, self.client);
        self.client = null;
    }
}

// --- common ---

fn void? RemoteSpy.listen(&self) {
    if (!self.client) return CLIENT_NOT_INITIALIZED~;

    LargeInteger* timeout_ptr = (LargeInteger*)&PACKET_INTERVAL;
    while (self.is_running) {
        int status = ntapi::wait_for_single_object(self.engine.ipc.semaphore, false, timeout_ptr);
        if (ntapi::failure(status)) continue;

        while (try packet = self.engine.ipc.buffer.pop()) {
            if (!self.on_event) continue;
            self.pool.push(&worker_thread, self, packet)!!;
        }
    }
}

// --- helpers ---

fn void? RemoteSpy.spawn_exit_handler(&self) @private {
    if (!self.is_running) return;

    Thread thread;
    thread.create(fn int (void* arg) {
        RemoteSpy* rspy = (RemoteSpy*)arg;
        ntapi::wait_for_single_object(rspy.client.get_process_handle(), false, (LargeInteger*)&winapi::INFINITE);
        rspy.is_running = false;
        return 0;
    }, self)!;

    thread.detach();
}

fn void worker_thread(any[] args) @private => @pool_init(mem, 64) {
    RemoteSpy* spy_ptr = *anycast(args[0], RemoteSpy*)!!;
    Packet* packet = anycast(args[1], Packet)!!;
    spy_ptr.on_event(spy_ptr, packet);
}
