module msvc_ext::vector;

import msvc_ext;
import nt_ext;

struct Vector<Type> {
    struct iterators {
        Type* begin;
        Type* end;
        Type* storage;
    }
}

struct VectorEx<Type> {
    inline WrapperEx{Vector{Type}} base;
    Allocator allocator;
    Type[] data;
}

fn Type Vector.get(&self, usz index) @operator([]) {
    return *(self.iterators.begin + index);
}

fn usz Vector.count(&self) @operator(len) {
    if (self.iterators.begin == null || self.iterators.begin >= self.iterators.end) return 0;
    return (usz)(self.iterators.end - self.iterators.begin);
}

fn void? VectorEx.init(&self, Allocator allocator, Memory* memory, uptr address) {
    self.base.init(memory, address)!;
    self.allocator = allocator;
    return self.refresh()!;
}

fn void VectorEx.free(&self) {
    if (self.data.ptr) allocator::free(self.allocator, self.data.ptr);
}

fn Type VectorEx.get(&self, usz index) @operator([]) {
    return self.data[index];
}

fn Type* VectorEx.get_ref(&self, usz index) @operator(&[]) {
    return &self.data[index];
}

fn usz VectorEx.count(&self) @operator(len) {
    return self.data.len;
}

fn uptr VectorEx.get_address(&self, Type* ptr) {
    if (self.data.ptr > ptr || ptr >= (self.data.ptr + self.data.len)) return 0;
    return (uptr)(self.iterators.begin + (ptr - self.data.ptr));
}

fn void? VectorEx.refresh(&self) {
    self.memory.read_bytes(self.address, ((char*)&self.internal)[:$sizeof(self.internal)])!;

    usz new_count = self.internal.count();
    if (new_count == 0) return;

    // if the new count exceeds the current data capacity, reallocate
    if (new_count > self.data.len) {
        self.free();
        self.data = allocator::alloc_array(self.allocator, Type, new_count);
    }

    self.memory.read_bytes((uptr)self.iterators.begin, ((char*)self.data.ptr)[:new_count * Type.sizeof])!;
}
