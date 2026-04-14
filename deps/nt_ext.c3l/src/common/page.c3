module nt_ext::page @if (env::WIN32);

import nt_ext;
import ntapi, winapi;

struct PageIterator {
    Memory* memory;
    uptr cursor;
}

fn void PageIterator.init(&self, Memory* memory) {
    self.memory = memory;
    self.cursor = 0;
}

fn MemoryBasicInformation? PageIterator.next(&self) {
    if (self.cursor >= 0x7FFFFFFFFFFFF) return faults::OUT_OF_BOUNDS~;

    MemoryBasicInformation mbi;
    self.memory.query(self.cursor, &mbi)!;
    self.cursor += mbi.region_size;

    return mbi;
}
