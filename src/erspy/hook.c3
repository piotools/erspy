module erspy::hook;

import erspy;

import std::collections::map;

import ntapi, winapi;
import nt_ext, msvc_ext;
import roblox;

macro get_var_offset(val) {
    return (uint)((uptr)val - (uptr)&erspy::stub::main_stub);
}

macro get_var_ptr(char[] buffer, void* val) {
    uptr offset = get_var_offset(val);
    return (void**)((uptr)buffer.ptr + offset);
}

struct HookState {
    uptr address;
    char[] old_bytes;
    uint old_protect;
    HashMap{uptr, uptr} old_callbacks;
}

struct HookEngine {
    Allocator allocator;
    Memory* memory;
    uptr base_address;

    Ipc ipc;
    HookState state;

    RemoteFunction generic_caller;
}

fn void? HookEngine.init(&self, Allocator allocator, Client* client) {
    self.allocator = allocator;
    self.memory = client.memory;
    self.base_address = client.base_address;

    self.ipc.init(client.memory.process_handle)!;

    self.install_stub()!;
    self.state.old_callbacks.init(allocator);

    self.generic_caller = client.remote.create_function(0)!;
}

fn void? HookEngine.deinit(&self) {
    self.restore_hooks()!;
    self.generic_caller.deinit()!;
    self.state.old_callbacks.free();
    self.uninstall_stub()!;
}

fn void? HookEngine.install_hooks(&self) {
    self.install_hook(RELIABLE, self.base_address + offsets::FIRE_SERVER)!;
    self.install_hook(UNRELIABLE, self.base_address + offsets::UNRELIABLE_FIRE_SERVER)!;
    self.install_hook(FUNCTION, self.base_address + offsets::INVOKE_SERVER, true)!;
}

fn void? HookEngine.toggle_hooks(&self, bool value) {
    if (value) {
        self.install_hooks()!;
    } else {
        self.restore_hooks()!;
    }
}

fn void? HookEngine.recall_packet(&self, Packet* packet) {
    uptr args_ptr = self.memory.allocate(size: $sizeof(packet.args) + BoostFunction.sizeof * 2)!;
    uptr extras_ptr = args_ptr + $sizeof(packet.args);
    uptr[2] extras = {extras_ptr, extras_ptr + BoostFunction.sizeof};

    if (packet.args.ptr) {
        self.memory.write_type(uint, (uptr)packet.args.ref_object + RefObject.uses.offsetof, 3)!;
        self.memory.write_type($typeof(packet.args), args_ptr, packet.args)!;
    }

    self.generic_caller.set_function(packet.original_cb)!;
    self.generic_caller.call(packet.remote, args_ptr, ...extras)!;

    (void)self.memory.free(args_ptr);
}

fn void? HookEngine.install_stub(&self) @private {
    char[] shellcode = erspy::stub::copy_bytes(self.allocator);
    defer allocator::free(self.allocator, shellcode.ptr);

    *get_var_ptr(shellcode, &erspy::stub::context.shared) = self.ipc.r_buffer;
    *get_var_ptr(shellcode, &erspy::stub::context.semaphore) = self.ipc.r_semaphore;

    ScanResult cave = scanner::find_code_cave(self.allocator, self.memory, shellcode.len)!;
    defer cave.free();

    self.state.old_bytes = allocator::alloc_array(self.allocator, char, shellcode.len);
    self.memory.read_bytes(cave.address, self.state.old_bytes)!;

    self.memory.protect(cave.address, shellcode.len, winapi::PAGE_EXECUTE_READWRITE, &self.state.old_protect)!;
    self.memory.write_bytes(cave.address, shellcode)!;

    self.state.address = cave.address;
}

fn void? HookEngine.uninstall_stub(&self) @private {
    if (self.state.address != 0) {
        self.memory.write_bytes(self.state.address, self.state.old_bytes)!;
        self.memory.protect(self.state.address, self.state.old_bytes.len, self.state.old_protect)!;
    }

    if (self.state.old_bytes.ptr) {
        allocator::free(self.allocator, self.state.old_bytes.ptr);
    }
}

fn void? HookEngine.patch_callback(&self, EventType type, uptr callback) @private {
    uint struct_offset = erspy::stub::StubContext.old_callbacks.offsetof + (type.ordinal++ * OriginalCallback.sizeof);
    uint offset = get_var_offset(&erspy::stub::context) + struct_offset;
    self.memory.write_type(uptr, self.state.address + offset, callback)!;
}

fn void? HookEngine.install_hook(&self, EventType type, uptr descriptor, bool is_func_yield = false) @private {
    uptr callback_ptr = descriptor + (is_func_yield ? offsets::BOUND_YIELD_FUNCTION_CALLBACK : offsets::BOUND_FUNCTION_CALLBACK);
    uptr callback = self.memory.read_type(uptr, callback_ptr)!;

    self.state.old_callbacks[callback_ptr] = callback;
    self.patch_callback(type, callback)!;

    uptr detour_addr = self.state.address + get_stub_offset(type);
    self.memory.write_type(uptr, callback_ptr, detour_addr)!;
}

fn void? HookEngine.restore_hooks(&self) @private {
    if (!self.state.old_callbacks.is_initialized()) return;

    self.state.old_callbacks.@each(; key, value) {
        self.memory.write_type(uptr, key, value)!;
    };

    self.state.old_callbacks.clear();
}

fn usz get_stub_offset(EventType type) @private {
    uptr base = (uptr)&stub::main_stub;
    switch (type) {
        case RELIABLE:
            return (uptr)&stub::reliable_stub - base;
        case UNRELIABLE:
            return (uptr)&stub::unreliable_stub - base;
        case FUNCTION:
            return (uptr)&stub::function_stub - base;
        default:
            return 0;
    }
}
