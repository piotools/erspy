module nt_ext::memory @if (env::WIN32);

import nt_ext::mod;
import ntapi, winapi;

faultdef
    OPEN_PROCESS_FAILED,
    PROCESS_QUERY_FAILED,
    MEMORY_QUERY_FAILED,
    ALLOCATE_FAILED,
    FREE_FAILED,
    PROTECT_FAILED,
    READ_FAILED,
    WRITE_FAILED;

struct Memory {
    uint process_id;
    void* process_handle;
    Peb peb;
}

fn void? Memory.open(&self, uint process_id, uint desired_access = winapi::PROCESS_ALL_ACCESS) {
    ClientId client_id;
    client_id.unique_process = (void*)(uptr)process_id;

    int status = ntapi::open_process(&self.process_handle, desired_access, && (ObjectAttributes) {}, &client_id);
    if (ntapi::failure(status)) return OPEN_PROCESS_FAILED~;

    self.process_id = process_id;
    self.peb = self.get_peb()!;
}

fn void Memory.close(&self) {
    if (self.process_handle) {
        ntapi::close(self.process_handle);
        self.process_handle = null;
    }
}

fn ModuleIterator? Memory.get_modules(&self) {
    ModuleIterator iterator;
    iterator.init(self)!;
    return iterator;
}

fn void? Memory.query(&self, uptr address, MemoryBasicInformation* info_ptr) {
    int status = ntapi::query_virtual_memory(
        self.process_handle,
        (void*)address,
        MEMORY_BASIC_INFORMATION,
        info_ptr,
        MemoryBasicInformation.sizeof,
        null
    );

    if (ntapi::failure(status)) return MEMORY_QUERY_FAILED~;
}

fn uptr? Memory.allocate(
    &self,
    uptr address = 0,
    usz size = 0x1000,
    uint type = winapi::MEM_COMMIT | winapi::MEM_RESERVE,
    uint protect = winapi::PAGE_READWRITE
) {
    uptr result = address;
    int status = ntapi::allocate_virtual_memory(self.process_handle, &result, 0, &size, type, protect);
    if (ntapi::failure(status)) return ALLOCATE_FAILED~;
    return result;
}

fn void? Memory.free(&self, uptr address, usz size = 0, uint type = winapi::MEM_RELEASE) {
    int status = ntapi::free_virtual_memory(self.process_handle, &address, &size, type);
    if (ntapi::failure(status)) return FREE_FAILED~;
}

fn void? Memory.protect(&self, uptr address, usz size = 1, uint protect, uint* old_protect_ptr = && {}) {
    int status = ntapi::protect_virtual_memory(self.process_handle, &address, &size, protect, old_protect_ptr);
    if (ntapi::failure(status)) return PROTECT_FAILED~;
}

fn void? Memory.read_bytes(&self, uptr address, char[] slice, usz* bytes_read = null) {
    int status = ntapi::read_virtual_memory(self.process_handle, (void*)address, slice.ptr, slice.len, bytes_read);
    if (ntapi::failure(status)) return READ_FAILED~;
}

fn void? Memory.write_bytes(&self, uptr address, char[] slice, usz* bytes_written = null) {
    int status = ntapi::write_virtual_memory(self.process_handle, (void*)address, slice.ptr, slice.len, bytes_written);
    if (ntapi::failure(status)) return WRITE_FAILED~;
}

macro Memory.read_type(&self, $Type, uptr address) {
    $Type value;
    self.read_bytes(address, ((char*)&value)[:$Type.sizeof])!;
    return value;
}

macro Memory.write_type(&self, $Type, uptr address, value) {
    self.write_bytes(address, ((char*)&value)[:$Type.sizeof])!;
}

fn uptr Memory.get_base_address(&self) @inline => (uptr)self.peb.image_base_address;
fn bool Memory.is_initialized(&self) @inline => self.process_id && self.process_handle;
fn bool Memory.is_valid(&self) @inline => self.is_initialized() && self.process_handle != winapi::INVALID_HANDLE_VALUE;

// --- helpers ---

fn Peb? Memory.get_peb(&self) {
    ProcessBasicInformation pbi;

    int status = ntapi::query_info_process(
        self.process_handle,
        PROCESS_BASIC_INFORMATION,
        &pbi,
        ProcessBasicInformation.sizeof,
        null
    );

    if (ntapi::failure(status) || !pbi.peb_base_address) return PROCESS_QUERY_FAILED~;

    return self.read_type(Peb, (uptr)pbi.peb_base_address)!;
}
