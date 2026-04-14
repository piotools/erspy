module erspy::stub;

import erspy::packet;

import std::collections::enummap;
import ntapi, winapi;
import msvc_ext;
import roblox;

attrdef @RemoteCode = @nostrip, @section(".text$erspy");

alias NtReleaseSemaphore = fn int (void*, uint, uint*);
alias OriginalCallback = fn void* (...);

struct StubContext {
    NtReleaseSemaphore release_fn;
    PacketBuffer* shared;
    void* semaphore;
    EnumMap{EventType, OriginalCallback} old_callbacks;
}

fn OriginalCallback main_stub(
    EventType type,
    Instance* remote,
    SharedPtr{Tuple}* args,
    BoostFunction* a2,
    BoostFunction* a3
) @noinline @RemoteCode {
    if (args && args.ref_object) args.ref_object.uses++;

    OriginalCallback callback = context.old_callbacks[type];

    context.shared.push({
        .type = type,
        .remote = remote,
        .args = *args,
        .original_cb = (uptr)callback,
    });

    context.release_fn(context.semaphore, 1, null);
    return callback(remote, args, a2, a3);
}

fn void* reliable_stub(void* a0, void* a1, void* a2, void* a3) @RemoteCode {
    return main_stub(RELIABLE, a0, a1, a2, a3);
}

fn void* unreliable_stub(void* a0, void* a1, void* a2, void* a3) @RemoteCode {
    return main_stub(UNRELIABLE, a0, a1, a2, a3);
}

fn void* function_stub(void* a0, void* a1, void* a2, void* a3) @RemoteCode {
    return main_stub(FUNCTION, a0, a1, a2, a3);
}

StubContext context @RemoteCode;

fn char[] copy_bytes(Allocator allocator) {
    usz size = ((uptr)&context + StubContext.sizeof) - (uptr)&main_stub;
    char[] buffer = allocator::alloc_array(allocator, char, size);
    mem::copy(buffer.ptr, &main_stub, size);
    return buffer;
}

fn void context_init() @local @init {
    // pre-initialize the static funcs here

    int status = ntapi::protect_virtual_memory(
        winapi::INVALID_HANDLE_VALUE,
        &&(&main_stub),
        &&1,
        winapi::PAGE_EXECUTE_READWRITE,
        && {}
    );

    if (ntapi::failure(status)) return;

    context.release_fn = ntapi::get_proc_address(ntapi::get_module_base("ntdll.dll"), "NtReleaseSemaphore");
}
