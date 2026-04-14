module roblox::tree::instance;

import roblox;
import nt_ext, msvc_ext;

faultdef
    CHILDREN_EMPTY,
    PARENT_NOT_FOUND;

struct Instance {
    void* vftable;
    SharedPtr{Instance} self;
    ClassDescriptor* class_descriptor;
}

struct InstanceEx {
    inline WrapperEx{Instance} base;
    Allocator allocator;
}

fn void? InstanceEx.init(&self, Allocator allocator, Memory* memory, uptr address) {
    self.base.init(memory, address)!;
    self.allocator = allocator;
}

fn ClassDescriptorEx? InstanceEx.get_class_descriptor(&self) {
    ClassDescriptorEx descriptor;
    descriptor.init(self.allocator, self.memory, (uptr)self.class_descriptor)!;
    return descriptor;
}

fn String? InstanceEx.get_name(&self) {
    uptr name_addr = self.memory.read_type(uptr, self.address + offsets::INSTANCE_NAME)!;
    if (name_addr == 0) return faults::NAME_EMPTY~;
    return string::read_cpp_string(self.allocator, self.memory, name_addr)!;
}

fn InstancesEx? InstanceEx.get_children(&self) {
    uptr children_addr = self.memory.read_type(uptr, self.address + offsets::INSTANCE_CHILDREN)!;
    if (children_addr == 0) return CHILDREN_EMPTY~;

    InstancesEx children;
    children.init(self.allocator, self.memory, children_addr)!;
    return children;
}

fn InstanceEx? InstanceEx.get_parent(&self) {
    uptr parent_addr = self.memory.read_type(uptr, self.address + offsets::INSTANCE_PARENT)!;
    if (parent_addr == 0) return PARENT_NOT_FOUND~;

    InstanceEx parent;
    parent.init(self.allocator, self.memory, parent_addr)!;
    return parent;
}

fn String? InstanceEx.get_full_name(&self) {
    if (try parent = self.get_parent() && !parent.is_a("ServiceProvider")!) {
        String full_name = parent.get_full_name()!;
        defer full_name.free(self.allocator);

        String name = self.get_name()!;
        defer name.free(self.allocator);

        return string::format(self.allocator, "%s.%s", full_name, name);
    }

    return self.get_name()!;
}

fn bool? InstanceEx.is_a(&self, String className) @inline => self.get_class_descriptor()!.is_a(className)!;
