module ntapi @if (env::WIN32);

// functions

extern fn int create_section(
    void** section_handle,
    uint desired_access,
    ObjectAttributes* object_attributes,
    LargeInteger* maximum_size,
    uint section_page_protection,
    uint allocation_attributes,
    void* file_handle
) @cname("NtCreateSection");

extern fn int map_view_of_section(
    void* section_handle,
    void* process_handle,
    void** base_address,
    ulong zero_bits,
    usz commit_size,
    LargeInteger* section_offset,
    usz* view_size,
    SectionInherit inherit_disposition,
    uint allocation_type,
    uint page_protection
) @cname("NtMapViewOfSection");

extern fn int unmap_view_of_section(
    void* process_handle,
    void* base_address
) @cname("NtUnmapViewOfSection");

// enums

enum SectionInherit : const CUInt {
    VIEW_SHARE = 1,
    VIEW_UNMAP = 2,
}
