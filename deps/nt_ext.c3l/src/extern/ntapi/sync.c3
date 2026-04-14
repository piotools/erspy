module ntapi @if (env::WIN32);

// functions

extern fn int create_semaphore(
    void** semaphore_handle,
    uint desired_access,
    ObjectAttributes* object_attributes,
    uint initial_count,
    uint maximum_count
) @cname("NtCreateSemaphore");

extern fn int wait_for_single_object(
    void* handle,
    bool alertable,
    LargeInteger* timeout
) @cname("NtWaitForSingleObject");

extern fn int set_io_completion(
    void* io_completion_handle,
    void* key_context,
    void* apc_context,
    int io_status,
    ulong io_status_information
) @cname("NtSetIoCompletion");
