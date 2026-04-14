module nt_ext::rpc::function @if (env::WIN32);

import nt_ext;
import ntapi, winapi;

faultdef
    IO_COMPLETION_NOT_INITIALIZED,
    REMOTE_CONTEXT_NOT_INITIALIZED,
    SET_IO_COMPLETION_FAILED,
    WAIT_FAILED,
    SEMAPHORE_CREATE_FAILED;

alias Target = fn void* (...);

const uint MAX_ARGUMENTS @private = 4;

struct FunctionContext {
    void* semaphore;
    Target target_fn;
    void*[MAX_ARGUMENTS] args;
    void* result;
}

struct RemoteFunction {
    Memory* memory;
    Remote* remote;
    uptr address;
    void* semaphore;
    uptr context;
}

fn void? RemoteFunction.init(&self, Remote* remote, uptr address) {
    self.memory = remote.memory;
    self.remote = remote;
    self.address = address;

    self.init_semaphore()!;
    self.init_context()!;
}

fn void? RemoteFunction.deinit(&self) {
    if (self.context != 0) {
        self.memory.free(self.context)!;
        self.context = 0;
    }

    if (self.semaphore) {
        ntapi::close(self.semaphore);
        self.semaphore = null;
    }
}

fn void? RemoteFunction.set_function(&self, uptr address) @inline {
    self.memory.write_type(Target, self.context + FunctionContext.target_fn.offsetof, address)!;
}

macro RemoteFunction.call(&self, ..., bool ignore_result = false) {
    if (!self.remote.dispatcher.io_completion) return IO_COMPLETION_NOT_INITIALIZED~;
    if (self.context == 0) return REMOTE_CONTEXT_NOT_INITIALIZED~;

    $if $vacount > MAX_ARGUMENTS:
        $error("RemoteFunction.call only supports up to " +++ MAX_ARGUMENTS +++ " arguments.");
    $endif

    void*[MAX_ARGUMENTS] arguments;
    $for var $i = 0; $i < $vacount; $i++:
        arguments[$i] = (void*)$vaarg[$i];
    $endfor

    uptr args = self.context + FunctionContext.args.offsetof;
    self.memory.write_type(void*[MAX_ARGUMENTS], args, arguments)!;

    int send_status = ntapi::set_io_completion(
        self.remote.dispatcher.io_completion,
        (void*)self.remote.dispatcher.completion_key,
        (void*)self.context,
        0,
        0
    );

    if (ntapi::failure(send_status)) return SET_IO_COMPLETION_FAILED~;

    if (ignore_result) return null;

    int wait_status = ntapi::wait_for_single_object(self.semaphore, false, (LargeInteger*)&winapi::INFINITE);
    if (ntapi::failure(wait_status)) return WAIT_FAILED~;

    return self.memory.read_type(void*, self.context + FunctionContext.result.offsetof)!;
}

// --- helpers ---

fn void? RemoteFunction.init_semaphore(&self) @private {
    int status = ntapi::create_semaphore(
        &self.semaphore,
        winapi::SEMAPHORE_ALL_ACCESS,
        && (ObjectAttributes) { .length = ObjectAttributes.sizeof },
        0,
        8
    );

    if (ntapi::failure(status)) return SEMAPHORE_CREATE_FAILED~;
}

fn void? RemoteFunction.init_context(&self) @private {
    FunctionContext context;
    context.target_fn = (Target)(void*)self.address;

    int status = ntapi::duplicate_object(
        winapi::INVALID_HANDLE_VALUE,
        self.semaphore,
        self.memory.process_handle,
        &context.semaphore,
        winapi::DUPLICATE_SAME_ACCESS,
        0,
        0
    );

    if (ntapi::failure(status)) return faults::DUPLICATE_OBJECT_FAILED~;

    self.context = self.memory.allocate(size: FunctionContext.sizeof)!;
    self.memory.write_type(FunctionContext, self.context, context)!;
}
