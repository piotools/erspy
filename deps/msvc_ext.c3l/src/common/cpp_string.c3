module msvc_ext::string;

import logger;
import nt_ext;

struct CppString {
    union {
        char[15] buffer;
        char* ptr;
    }

    usz length;
    usz capacity;
}

fn String? read_cpp_string(Allocator allocator, Memory* memory, uptr address) {
    CppString local = memory.read_type(CppString, address)!;
    char[] data = allocator::alloc_array(allocator, char, local.length);

    if (local.capacity <= 15) {
        mem::copy(data.ptr, &local.buffer[0], local.length);
        return (String)data;
    }

    memory.read_bytes((uptr)local.ptr, data)!;
    return (String)data;
}
