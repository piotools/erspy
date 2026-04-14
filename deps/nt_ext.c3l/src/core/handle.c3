module nt_ext::handle @if (env::WIN32);

import nt_ext;
import ntapi, winapi;

faultdef HIJACK_FAILED;

struct HandleIterator {
    Allocator allocator;
    SystemHandleInformation* info;
}

fn void? HandleIterator.init(&self, Allocator allocator) {
    self.allocator = allocator;
    self.info = get_handle_info(allocator)!;
}

fn void HandleIterator.free(&self) {
    if (self.info) {
        allocator::free(self.allocator, self.info);
        self.info = null;
    }
}

fn SystemHandleTableEntryInfo HandleIterator.get(&self, usz index) @operator([]) {
    return *(&self.info.handles[0] + index);
}

fn usz HandleIterator.count(&self) @operator(len) {
    return self.info.number_of_handles;
}

// --- common ---

fn void*? hijack_from_owner(uint owner_pid, uint type_id, uint desired_access) {
    HandleIterator iterator;
    iterator.init(tmem)!;

    foreach (entry : iterator) {
        if (entry.unique_process_id != owner_pid || entry.object_type_index != type_id) continue;

        void*? local_handle = hijack_handle((uint)entry.unique_process_id, (void*)(uptr)entry.handle_value, desired_access);
        if (catch local_handle) continue;

        return local_handle;
    };

    return HIJACK_FAILED~;
}

fn void*? hijack_process(uint process_id, uint desired_access) {
    HandleIterator iterator;
    iterator.init(tmem)!;

    uint process_type_id = object::get_type_index("Process")!;
    ProcessBasicInformation pbi;

    foreach (entry : iterator) {
        if (entry.object_type_index != process_type_id) continue;

        void*? local_handle = hijack_handle((uint)entry.unique_process_id, (void*)(uptr)entry.handle_value, desired_access);
        if (catch local_handle) continue;

        int status = ntapi::query_info_process(
            local_handle,
            PROCESS_BASIC_INFORMATION,
            &pbi,
            ProcessBasicInformation.sizeof,
            null
        );

        if (ntapi::failure(status) || (uint)(uptr)pbi.unique_process_id != process_id) {
            ntapi::close(local_handle);
            continue;
        }

        return local_handle;
    };

    return HIJACK_FAILED~;
}

// --- helpers ---

fn SystemHandleInformation*? get_handle_info(Allocator allocator) @private {
    uint info_size = SystemHandleInformation.sizeof;
    SystemHandleInformation* info;

    while (true) {
        info = allocator::malloc(allocator, info_size);

        int status = ntapi::query_system_info(SYSTEM_HANDLE_INFORMATION, info, info_size, &info_size);
        if (ntapi::success(status)) break;

        allocator::free(allocator, info);
    }

    return info;
}

fn void*? hijack_handle(uint owner_pid, void* handle, uint desired_access) @private {
    ClientId client_id;
    client_id.unique_process = (void*)(uptr)owner_pid;

    void* duplicator;
    int open_status = ntapi::open_process(&duplicator, winapi::PROCESS_DUP_HANDLE, && (ObjectAttributes) {}, &client_id);

    if (ntapi::failure(open_status)) return faults::OPEN_PROCESS_FAILED~;
    defer ntapi::close(duplicator);

    void* result;
    int dupe_status = ntapi::duplicate_object(
        duplicator,
        handle,
        winapi::INVALID_HANDLE_VALUE,
        &result,
        desired_access,
        0,
        0
    );

    if (ntapi::failure(dupe_status)) return faults::DUPLICATE_OBJECT_FAILED~;

    return result;
}
