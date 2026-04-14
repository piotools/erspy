module msvc_ext::wrapper;

import nt_ext;

struct WrapperEx<Type> {
    inline Type internal;
    Memory* memory;
    uptr address;
}

fn void? WrapperEx.init(&self, Memory* memory, uptr address) {
    self.memory = memory;
    self.address = address;
    memory.read_bytes(address, ((char*)&self.internal)[:Type.sizeof])!;
}

fn bool WrapperEx.equals(&self, WrapperEx other) @operator(==) {
    return self.address == other.address;
}
