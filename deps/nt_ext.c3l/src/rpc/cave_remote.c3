module nt_ext::rpc::remote @if (env::WIN32);

import nt_ext;
import ntapi, winapi;

struct CaveRemote {
    inline Remote base;
    char[] old_bytes;
    uint old_protect;
}

fn void? CaveRemote.init(&self, Allocator allocator, Memory* memory) {
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

fn void? CaveRemote.deinit(&self) {
    if (self.dispatcher.completion_key != 0) {
        self.memory.free(self.dispatcher.completion_key)!;
        self.dispatcher.completion_key = 0;
    }

    if (self.dispatcher.address != 0 && self.old_bytes.ptr) {
        self.memory.write_bytes(self.dispatcher.address, self.old_bytes)!;
        self.memory.protect(self.dispatcher.address, self.old_bytes.len, self.old_protect)!;
        allocator::free(self.allocator, self.old_bytes.ptr);
    }

    if (self.dispatcher.io_completion) {
        ntapi::close(self.dispatcher.io_completion);
        self.dispatcher.io_completion = null;
    }
}

// --- helpers ---

fn void? CaveRemote.setup_dispatcher(&self) @private {
    char[] shellcode = stub::copy_bytes(self.allocator);
    defer allocator::free(self.allocator, shellcode.ptr);

    ScanResult cave = scanner::find_code_cave(self.allocator, self.memory, shellcode.len)!;
    defer cave.free();

    self.old_bytes = allocator::alloc_array(self.allocator, char, shellcode.len);
    self.memory.read_bytes(cave.address, self.old_bytes)!;

    self.memory.protect(cave.address, shellcode.len, winapi::PAGE_EXECUTE_READWRITE, &self.old_protect)!;
    self.memory.write_bytes(cave.address, shellcode)!;

    self.dispatcher.address = cave.address;
}
