module nt_ext::rpc::stub;

import nt_ext;
import ntapi, winapi;

attrdef @RemoteCode = @nostrip, @section(".text$rpc");

alias NtReleaseSemaphore = fn int (void*, uint, uint*);

struct StubContext {
    NtReleaseSemaphore release_fn;
}

fn void code(void*, void*, FunctionContext* request) @RemoteCode {
    request.result = request.target_fn(...request.args);
    context.release_fn(request.semaphore, 1, null);
}

StubContext context @RemoteCode;

fn char[] copy_bytes(Allocator allocator) {
    usz size = ((uptr)&context + StubContext.sizeof) - (uptr)&code;
    char[] buffer = allocator::alloc_array(allocator, char, size);
    mem::copy(buffer.ptr, &code, size);
    return buffer;
}

// --- misc ---

fn void context_init() @local @init {
    // pre-initialize the static funcs here

    int status = ntapi::protect_virtual_memory(
        winapi::INVALID_HANDLE_VALUE,
        &&(&code),
        &&1,
        winapi::PAGE_EXECUTE_READWRITE,
        && {}
    );

    if (ntapi::failure(status)) return;

    context.release_fn = ntapi::get_proc_address(ntapi::get_module_base("ntdll.dll"), "NtReleaseSemaphore");
}
