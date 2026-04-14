module nt_ext::process @if (env::WIN32);

import nt_ext;
import ntapi, winapi;

faultdef PROCESS_NOT_FOUND;

struct ProcessIterator {
    Allocator allocator;
    SystemProcessInformation* info;
    SystemProcessInformation* current;
}

fn void? ProcessIterator.init(&self, Allocator allocator) {
    self.allocator = allocator;
    self.info = get_process_info(self.allocator)!;
    self.current = self.info;
}

fn void ProcessIterator.free(&self) {
    if (self.info) {
        allocator::free(self.allocator, self.info);
        self.info = null;
    }
}

fn SystemProcessInformation? ProcessIterator.next(&self) {
    if (!self.current.next_entry_offset) return faults::OUT_OF_BOUNDS~;

    SystemProcessInformation* current = self.current;
    self.current = (SystemProcessInformation*)((uptr)current + current.next_entry_offset);

    return *current;
}

// --- common ---

fn uint? find_process_id(String process_name) {
    ProcessIterator iterator;
    iterator.init(mem)!;
    defer iterator.free();

    while (try entry = iterator.next()) {
        if (entry.image_name.buffer && entry.image_name == process_name) {
            return (uint)(uptr)entry.unique_process_id;
        }
    }

    return PROCESS_NOT_FOUND~;
}

fn bool is_active(void* handle) @inline {
    ProcessBasicInformation pbi;
    int status = ntapi::query_info_process(handle, PROCESS_BASIC_INFORMATION, &pbi, ProcessBasicInformation.sizeof, null);
    return ntapi::success(status) && pbi.exit_status == winapi::STILL_ACTIVE;
}

// --- helpers ---

fn SystemProcessInformation*? get_process_info(Allocator allocator) @private {
    uint info_size = SystemProcessInformation.sizeof;
    SystemProcessInformation* info;

    while (true) {
        info = allocator::malloc(allocator, info_size);

        int status = ntapi::query_system_info(SYSTEM_PROCESS_INFORMATION, info, info_size, &info_size);
        if (ntapi::success(status)) break;

        allocator::free(allocator, info);
    }

    return info;
}
