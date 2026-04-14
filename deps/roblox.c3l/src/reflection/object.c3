module roblox::reflection::object;

import roblox;
import nt_ext;
import msvc_ext;

faultdef BASE_NOT_FOUND;

struct ClassDescriptor {
    void* vftable;
    CppString* name;
}

struct ClassDescriptorEx {
    inline WrapperEx{ClassDescriptor} base;
    Allocator allocator;
}

fn void? ClassDescriptorEx.init(&self, Allocator allocator, Memory* memory, uptr address) {
    self.base.init(memory, address)!;
    self.allocator = allocator;
}

fn String? ClassDescriptorEx.get_name(&self) {
    uptr name_addr = (uptr)self.name;
    if (name_addr == 0) return faults::NAME_EMPTY~;
    return string::read_cpp_string(self.allocator, self.memory, name_addr)!;
}

fn ClassDescriptorEx? ClassDescriptorEx.get_base(&self) {
    uptr base_addr = self.memory.read_type(uptr, self.address + offsets::CLASS_DESCRIPTOR_BASE)!;
    if (base_addr == 0) return BASE_NOT_FOUND~;

    ClassDescriptorEx base;
    base.init(self.allocator, self.memory, base_addr)!;
    return base;
}

fn bool? ClassDescriptorEx.is_a(&self, String class_name) {
    String name = self.get_name()!;
    defer name.free(self.allocator);

    if (name == class_name) return true;
    if (try base = self.get_base()) return base.is_a(class_name)!;

    return false;
}
