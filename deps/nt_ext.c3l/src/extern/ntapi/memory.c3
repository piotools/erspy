module ntapi @if (env::WIN32);

// functions

extern fn int allocate_virtual_memory(
    void* process_handle,
    void* base_address,
    ulong zero_bits,
    usz* region_size,
    uint allocation_type,
    uint protect
) @cname("NtAllocateVirtualMemory");

extern fn int free_virtual_memory(
    void* process_handle,
    void* base_address,
    usz* region_size,
    uint free_type
) @cname("NtFreeVirtualMemory");

extern fn int protect_virtual_memory(
    void* process_handle,
    void* base_address,
    usz* region_size,
    uint new_protection,
    uint* old_protection
) @cname("NtProtectVirtualMemory");

extern fn int read_virtual_memory(
    void* process_handle,
    void* base_address,
    void* buffer,
    usz number_of_bytes_to_read,
    usz* number_of_bytes_read
) @cname("NtReadVirtualMemory");

extern fn int write_virtual_memory(
    void* process_handle,
    void* base_address,
    void* buffer,
    usz number_of_bytes_to_write,
    usz* number_of_bytes_written
) @cname("NtWriteVirtualMemory");

extern fn int query_virtual_memory(
    void* process_handle,
    void* base_address,
    MemoryInformationClass memory_information_class,
    void* memory_information,
    usz memory_information_length,
    usz* return_length
) @cname("NtQueryVirtualMemory");

// structs

struct MemoryBasicInformation {
    void* base_address;
    void* allocation_base;
    uint allocation_protect;
    ushort partition_id;
    usz region_size;
    uint state;
    uint protect;
    uint type;
}

// enums

enum MemoryInformationClass {
    MEMORY_BASIC_INFORMATION,
    MEMORY_WORKING_SET_INFORMATION,
    MEMORY_MAPPED_FILE_INFORMATION,
    MEMORY_REGION_INFORMATION,
    MEMORY_WORKING_SET_EX_INFORMATION,
    MEMORY_SHARED_COMMIT_INFORMATION,
    MEMORY_IMAGE_INFORMATION,
    MEMORY_REGION_INFORMATION_EX,
    MEMORY_PRIVILEGED_BASIC_INFORMATION,
    MEMORY_ENCLAVE_IMAGE_INFORMATION,
    MEMORY_BASIC_INFORMATION_CAPPED,
    MEMORY_PHYSICAL_CONTIGUITY_INFORMATION,
    MEMORY_BAD_INFORMATION,
    MEMORY_BAD_INFORMATION_ALL_PROCESSES,
    MEMORY_IMAGE_EXTENSION_INFORMATION,
    MAX_MEMORY_INFO_CLASS
}
