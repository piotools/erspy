module erspy::ipc;

import erspy::packet;

import std::collections::map;

import ntapi, winapi;
import nt_ext;

faultdef
    CREATE_SECTION_FAILED,
    MAP_VIEW_FAILED,
    CREATE_SEMAPHORE_FAILED,
    CLIENT_NOT_INITIALIZED;

struct Ipc {
    void* process_handle;
    PacketBuffer* buffer;
    PacketBuffer* r_buffer;
    void* semaphore;
    void* r_semaphore;
}

fn void? Ipc.init(&self, void* process_handle) {
    self.process_handle = process_handle;
    self.init_buffers()!;
    self.init_semaphores()!;
}

fn void Ipc.deinit(&self) {
    if (self.semaphore) {
        ntapi::close(self.semaphore);
        self.semaphore = null;
    }

    if (self.r_semaphore) {
        ntapi::close(self.r_semaphore);
        self.r_semaphore = null;
    }

    if (self.r_buffer) {
        ntapi::unmap_view_of_section(self.process_handle, self.r_buffer);
    }

    if (self.buffer) {
        ntapi::unmap_view_of_section(winapi::INVALID_HANDLE_VALUE, self.buffer);
    }
}

fn void? Ipc.init_buffers(&self) @private {
    usz size = PacketBuffer.sizeof;
    void* section;

    int status = ntapi::create_section(
        &section,
        winapi::SECTION_ALL_ACCESS,
        null,
        (LargeInteger*)&size,
        winapi::PAGE_READWRITE,
        winapi::SEC_COMMIT,
        null
    );

    if (ntapi::failure(status)) return CREATE_SECTION_FAILED~;
    defer ntapi::close(section);

    self.buffer = map_shared(winapi::INVALID_HANDLE_VALUE, section, 0, size, winapi::PAGE_READWRITE)!;
    self.r_buffer = map_shared(self.process_handle, section, 0, size, winapi::PAGE_READWRITE)!;
}

fn void? Ipc.init_semaphores(&self) @private {
    int create_status = ntapi::create_semaphore(
        &self.semaphore,
        winapi::SEMAPHORE_ALL_ACCESS,
        && (ObjectAttributes) { .length = ObjectAttributes.sizeof },
        0,
        8
    );

    if (ntapi::failure(create_status)) return CREATE_SEMAPHORE_FAILED~;

    int dupe_status = ntapi::duplicate_object(
        winapi::INVALID_HANDLE_VALUE,
        self.semaphore,
        self.process_handle,
        &self.r_semaphore,
        winapi::DUPLICATE_SAME_ACCESS,
        0,
        0
    );

    if (ntapi::failure(dupe_status)) return faults::DUPLICATE_OBJECT_FAILED~;
}

fn void*? map_shared(void* handle, void* section, uptr address, usz size, uint protect) @private {
    void* result = (void*)address;
    int status = ntapi::map_view_of_section(
        section,
        handle,
        &result,
        0,
        size,
        && (LargeInteger) {},
        &size,
        VIEW_SHARE,
        0,
        protect
    );

    if (ntapi::failure(status)) return MAP_VIEW_FAILED~;

    return result;
}
