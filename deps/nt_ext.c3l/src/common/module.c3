module nt_ext::mod @if (env::WIN32);

import nt_ext;

import logger;
import ntapi, winapi;

faultdef MODULE_NOT_FOUND;

struct ModuleIterator {
    Memory* memory;
    uptr current_addr, stop_addr;
}

fn void? ModuleIterator.init(&self, Memory* memory) {
    self.memory = memory;

    PebLdrData ldr = memory.read_type(PebLdrData, (uptr)memory.peb.ldr)!;
    uptr list_head_addr = (uptr)memory.peb.ldr + $offsetof(ldr.in_memory_order_module_list);

    self.current_addr = (uptr)ldr.in_memory_order_module_list.flink;
    self.stop_addr = list_head_addr;
}

fn LdrDataTableEntry? ModuleIterator.next(&self) {
    if (self.current_addr == self.stop_addr) return faults::OUT_OF_BOUNDS~;

    LdrDataTableEntry entry = self.read_entry(self.current_addr)!;
    self.current_addr = (uptr)entry.in_memory_order_links.flink;

    return entry;
}

// --- common ---

fn LdrDataTableEntry? find_module(Memory* memory, String module_name) {
    ModuleIterator iterator;
    iterator.init(memory)!;

    while (try entry = iterator.next()) {
        UnicodeString dll_name = entry.base_dll_name;
        if (dll_name.length != module_name.len * 2) continue;

        char[winapi::MAX_MODULE_NAME32] buffer;
        memory.read_bytes((uptr)dll_name.buffer, buffer[:dll_name.length])!;
        dll_name.buffer = (WString)&buffer;

        if (dll_name == module_name) return entry;
    }

    return MODULE_NOT_FOUND~;
}

// --- helpers ---

fn LdrDataTableEntry? ModuleIterator.read_entry(&self, uptr link_addr) @private {
    uptr entry_addr = (uptr)ntapi::containing_record(link_addr, LdrDataTableEntry, "in_memory_order_links");
    return self.memory.read_type(LdrDataTableEntry, entry_addr)!;
}
