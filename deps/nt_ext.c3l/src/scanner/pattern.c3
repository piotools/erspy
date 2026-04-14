module nt_ext::scanner @if (env::WIN32);

import nt_ext;

faultdef BUFFER_TOO_SMALL, PATTERN_NOT_FOUND;

struct PatternScanner {
    inline BaseScanner base;
    String pattern;
}

fn void PatternScanner.init(&self, Allocator allocator, Memory* memory, String pattern) {
    self.base.init(allocator, memory);
    self.pattern = pattern;
}

fn ScanResult? PatternScanner.next(&self) {
    while (try chunk = self.get_chunk()) {
        if (try index = find_pattern_buf(chunk[self.state.cursor..], self.pattern)) {
            return self.get_scan_result(chunk, index);
        }

        self.state.cursor = chunk.len;
    }

    return faults::OUT_OF_BOUNDS~;
}

// --- common ---

fn ScanResult? find_pattern(
    Allocator allocator,
    Memory* memory,
    String pattern,
    scanner::ScannerFilterFn filter = scanner::DEFAULT_FILTER
) {
    PatternScanner scanner;
    scanner.init(allocator, memory, pattern);
    defer scanner.deinit();
    return scanner.next()!;
}

// --- helpers ---

fn usz? find_pattern_buf(char[] buffer, String pattern) @private {
    if (buffer.len < pattern.len) return BUFFER_TOO_SMALL~;

    for (usz i = 0; i < buffer.len - pattern.len; i++) {
        bool match = true;
        for (usz j = 0; j < pattern.len; j++) {
            char byte = pattern[j];
            if (byte != '?' && buffer[i + j] != byte) {
                match = false;
                break;
            }
        }

        if (match) return i;
    }

    return PATTERN_NOT_FOUND~;
}
