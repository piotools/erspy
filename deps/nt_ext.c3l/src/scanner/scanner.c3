module nt_ext::scanner @if (env::WIN32);

import nt_ext;
import std::io;
import std::math;
import ntapi, winapi;

alias ScannerFilterFn = fn bool (MemoryBasicInformation*);
const ScannerFilterFn DEFAULT_FILTER = fn (MemoryBasicInformation* page) => (page.type == winapi::MEM_PRIVATE);

struct ScanResult {
    Allocator allocator;
    char[] data;
    uptr address;
    usz offset;
}

struct ScannerState {
    MemoryBasicInformation mbi;
    char[] buffer;
    usz cursor;
    bool active;
}

struct BaseScanner {
    Allocator allocator;
    Memory* memory;
    PageIterator pages;
    ScannerState state;
    ScannerFilterFn filter;
}

fn void ScanResult.free(&self) {
    if (self.data.ptr) {
        allocator::free(self.allocator, self.data.ptr);
    }
}

fn void BaseScanner.init(&self, Allocator allocator, Memory* memory, ScannerFilterFn filter = DEFAULT_FILTER) {
    self.allocator = allocator;
    self.memory = memory;
    self.pages.init(memory);
    self.filter = filter;
}

fn void BaseScanner.deinit(&self) {
    self.state.active = false;

    if (self.state.buffer.ptr) {
        allocator::free(self.allocator, self.state.buffer.ptr);
    }
}

fn char[]? BaseScanner.get_chunk(&self) {
    if (self.state.active && self.state.cursor >= self.state.buffer.len) {
        self.state.active = false;
    }

    if (self.state.active) return self.state.buffer;

    while (try page = self.next_page()) {
        if (page.region_size > self.state.buffer.len) {
            if (self.state.buffer.ptr) {
                allocator::free(self.allocator, self.state.buffer.ptr);
            }
            self.state.buffer = allocator::alloc_array(self.allocator, char, page.region_size);
        }

        char[] buffer = self.state.buffer[:page.region_size];
        if (catch self.memory.read_bytes((uptr)page.base_address, buffer)) {
            continue;
        }

        self.state.mbi = page;
        self.state.cursor = 0;
        self.state.active = true;

        return buffer;
    }

    return faults::OUT_OF_BOUNDS~;
}

fn ScanResult? BaseScanner.get_scan_result(&self, char[] chunk, usz index) {
    usz abs_offset = self.state.cursor + index;

    char[] data = allocator::alloc_array(self.allocator, char, chunk.len);
    mem::copy(data.ptr, chunk.ptr, chunk.len);

    ScanResult result = {
        .allocator = self.allocator,
        .address = (uptr)self.state.mbi.base_address + abs_offset,
        .offset = abs_offset,
        .data = data,
    };

    self.state.cursor = abs_offset + 1;

    return result;
}

// --- helpers ---

fn MemoryBasicInformation? BaseScanner.next_page(&self) @private {
    while (try page = self.pages.next()) {
        bool is_commit = page.state == winapi::MEM_COMMIT;
        bool is_restricted = (page.protect & (winapi::PAGE_NOACCESS | winapi::PAGE_GUARD)) != 0;

        if (!is_commit || is_restricted) continue;
        if (self.filter && !self.filter(&page)) continue;

        return page;
    }

    return faults::OUT_OF_BOUNDS~;
}
