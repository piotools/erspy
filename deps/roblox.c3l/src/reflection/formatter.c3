module roblox::reflection::formatter;

import logger;
import std::collections::enummap;
import nt_ext;
import msvc_ext;
import roblox;

alias VariantFormatterFn = fn String (Allocator, VariantEx*, Type*);

EnumMap{TTypeId, VariantFormatterFn} handlers;

fn String format_default(Allocator allocator, VariantEx*, Type* type_info) @private {
    return string::format(allocator, "nil --[[%s]]", type_info.id.nameof);
}

fn String format_string(Allocator allocator, VariantEx* variant, Type*) @private {
    CppString* local = &variant.value.s;
    if (local.capacity <= 15) {
        String buffer = (String)local.buffer[:local.length];
        return buffer.escape(allocator, false);
    }

    char[] data = allocator::alloc_array(allocator, char, local.length);
    defer allocator::free(allocator, data.ptr);

    variant.memory.read_bytes((uptr)local.ptr, data)!!;
    return ((String)data).escape(allocator, false);
}

fn String format_primitive(Allocator allocator, VariantEx* variant, Type* type_info) @private {
    switch (type_info.id) {
        case BOOL: return (variant.value.b ? "true" : "false").copy(allocator);
        case INT: return string::format(allocator, "%d", variant.value.i);
        case INT64: return string::format(allocator, "%d", variant.value.l);
        case FLOAT: return string::format(allocator, "%f", variant.value.f);
        case DOUBLE: return string::format(allocator, "%f", variant.value.d);
        case STRING: return format_string(allocator, variant, type_info);
        default: return ("nil").copy(allocator);
    }
}

fn String format_vector(Allocator allocator, VariantEx* variant, Type* type_info) @private {
    switch (type_info.id) {
        case VECTOR2: return variant.value.v2.to_string(allocator);
        case VECTOR3: return variant.value.v3.to_string(allocator);
        case VECTOR2INT16: return variant.value.v2i.to_string(allocator);
        case VECTOR3INT16: return variant.value.v3i.to_string(allocator);
        default: return ("nil --[[Unknown Vector Type]]").copy(allocator);
    }
}

fn String format_array(Allocator allocator, VariantEx* variant, Type*) @private {
    TupleEx array;
    if (catch array.init(allocator, variant.memory, variant.value.address)) {
        return ("{}").copy(allocator);
    }
    defer array.free();
    return array.to_string(allocator);
}

fn String format_instance(Allocator allocator, VariantEx* variant, Type*) @private {
    InstanceEx instance;
    if (catch instance.init(allocator, variant.memory, variant.value.address)) {
        return ("nil").copy(allocator);
    }
    return instance.get_full_name() ?? ("nil --[[Unknown Instance]]").copy(allocator);
}

fn void map_init() @local @init {
    handlers.init(&format_default); // for unhandled types

    handlers[VOID] = &format_primitive;
    handlers[BOOL] = &format_primitive;
    handlers[INT] = &format_primitive;
    handlers[INT64] = &format_primitive;
    handlers[FLOAT] = &format_primitive;
    handlers[DOUBLE] = &format_primitive;
    handlers[STRING] = &format_primitive;

    handlers[VECTOR2] = &format_vector;
    handlers[VECTOR3] = &format_vector;
    handlers[VECTOR2INT16] = &format_vector;
    handlers[VECTOR3INT16] = &format_vector;

    handlers[RAY] = fn (Allocator a, VariantEx* v, Type*) => v.value.r.to_string(a);
    handlers[RECT2D] = fn (Allocator a, VariantEx* v, Type*) => v.value.r2d.to_string(a);

    handlers[TUPLE] = &format_array;
    handlers[VALUE_ARRAY] = &format_array;
    handlers[INSTANCE] = &format_instance;
}
