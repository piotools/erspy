module nt_ext::rpc::remote @if (env::WIN32);

import nt_ext;
import ntapi, winapi;

struct Dispatcher {
    void* io_completion;
    uptr address;
    uptr completion_key;
}

struct Remote {
    Allocator allocator;
    Memory* memory;
    Dispatcher dispatcher;
}

fn void? Remote.init(&self, Allocator allocator, Memory* memory) {
    self.allocator = allocator;
    self.memory = memory;

    self.dispatcher.io_completion = handle::hijack_from_owner(
        self.memory.process_id,
        object::get_type_index("IoCompletion")!,
        winapi::DUPLICATE_SAME_ACCESS
    )!;

    self.setup_dispatcher()!;
    self.init_completion_key()!;
}

fn void? Remote.deinit(&self) {
    if (self.dispatcher.completion_key != 0) {
        self.memory.free(self.dispatcher.completion_key)!;
        self.dispatcher.completion_key = 0;
    }

    if (self.dispatcher.address != 0) {
        self.memory.free(self.dispatcher.address)!;
        self.dispatcher.address = 0;
    }

    if (self.dispatcher.io_completion) {
        ntapi::close(self.dispatcher.io_completion);
        self.dispatcher.io_completion = null;
    }
}

fn RemoteFunction? Remote.create_function(&self, uptr address) {
    RemoteFunction func;
    func.init(self, address)!;
    return func;
}

// --- helpers ---

fn void? Remote.setup_dispatcher(&self) @private {
    char[] shellcode = stub::copy_bytes(self.allocator);
    defer allocator::free(self.allocator, shellcode.ptr);

    self.dispatcher.address = self.memory.allocate(size: shellcode.len, protect: winapi::PAGE_EXECUTE_READWRITE)!;
    self.memory.write_bytes(self.dispatcher.address, shellcode)!;
}

fn void? Remote.init_completion_key(&self) @private {
    TpDirect direct;
    direct.callback = (void*)self.dispatcher.address;

    self.dispatcher.completion_key = self.memory.allocate(size: TpDirect.sizeof)!;
    self.memory.write_type(TpDirect, self.dispatcher.completion_key, direct)!;
}
