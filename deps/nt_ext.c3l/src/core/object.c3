module nt_ext::object @if (env::WIN32);

import std::collections::map;
import ntapi;

macro align_up(uptr ptr) @private {
    uptr alignment = uptr.sizeof;
    return (ptr + (alignment - 1)) & ~(alignment - 1);
}

HashMap {String, ObjectTypeInformation} types_map;

fn void types_init() @local @init {
    ObjectTypesInformation*? types_info = get_types_info(mem);
    if (catch types_info) return;

    uptr current_addr = align_up(((uptr)types_info) + ObjectTypesInformation.sizeof);

    types_map.init(mem);

    for (uint i = 0; i < types_info.number_of_types; i++) {
        ObjectTypeInformation* entry = (ObjectTypeInformation*)current_addr;
        String? type_name = entry.type_name.to_string();
        if (catch type_name) continue;

        types_map[type_name] = *entry;

        uptr next_addr = current_addr + ObjectTypeInformation.sizeof + entry.type_name.maximum_length;
        current_addr = align_up(next_addr);
    }
}

fn void types_free() @local @finalizer {
    if (types_map.is_initialized()) types_map.free();
}

// --- common ---

fn uint? get_type_index(String type_name) {
    ObjectTypeInformation* type_info = types_map.get_ref(type_name)!;
    return type_info.type_index;
}

// --- helpers --

fn ObjectTypesInformation*? get_types_info(Allocator allocator) @private {
    uint info_size = ObjectTypesInformation.sizeof;
    ObjectTypesInformation* info;

    while (true) {
        info = allocator::malloc(allocator, info_size);

        int status = ntapi::query_object(null, OBJECT_TYPES_INFORMATION, info, info_size, &info_size);
        if (ntapi::success(status)) break;

        allocator::free(allocator, info);
    }

    return info;
}
