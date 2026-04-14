module nt_ext::scanner @if (env::WIN32);

import nt_ext;
import ntapi, winapi;

faultdef BUUFFER_TOO_SMALL, CODECAVE_NOT_FOUND;

const ScannerFilterFn CAVE_FILTER = fn (MemoryBasicInformation* mbi) {
    bool is_executeable = (mbi.protect & (winapi::PAGE_READONLY | winapi::PAGE_EXECUTE_READ)) != 0;
    bool is_image = mbi.type == winapi::MEM_IMAGE;
    return is_executeable && is_image;
};

struct CodeCaveScanner {
    inline BaseScanner base;
    usz cave_size;
}

fn void CodeCaveScanner.init(&self, Allocator allocator, Memory* memory, usz cave_size = 100) {
    self.base.init(allocator, memory);
    self.filter = CAVE_FILTER;
    self.cave_size = cave_size;
}

fn ScanResult? CodeCaveScanner.next(&self) {
    while (try chunk = self.get_chunk()) {
        if (try index = find_repeated_chars(chunk[self.state.cursor..], self.cave_size)) {
            return self.get_scan_result(chunk, index);
        }

        self.state.cursor = chunk.len;
    }

    return faults::OUT_OF_BOUNDS~;
}

// --- common ---

fn ScanResult? find_code_cave(Allocator allocator, Memory* memory, usz size = 100) {
    CodeCaveScanner scanner;
    scanner.init(allocator, memory, size);
    defer scanner.deinit();
    return scanner.next()!;
}

// --- helpers ---

fn usz? find_repeated_chars(char[] buffer, usz limit) @private {
    if (buffer.len < limit) return BUFFER_TOO_SMALL~;

    usz count = 1;
    for (usz i = 1; i < buffer.len; i++) {
        if (buffer[i] != buffer[i - 1]) {
            count = 1;
            continue;
        }

        if (++count >= limit) return i - limit + 1;
    }

    return CODECAVE_NOT_FOUND~;
}
