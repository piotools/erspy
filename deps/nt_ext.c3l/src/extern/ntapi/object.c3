module ntapi @if (env::WIN32);

// functions

extern fn int query_object(
    void* handle,
    ObjectInformationClass object_information_class,
    void* object_information,
    uint object_information_length,
    uint* return_length
) @cname("NtQueryObject");

extern fn int duplicate_object(
    void* source_process_handle,
    void* source_handle,
    void* target_process_handle,
    void** target_handle,
    uint desired_access,
    uint handle_attributes,
    uint options
) @cname("NtDuplicateObject");

extern fn bool close(void* handle) @cname("NtClose");

// structs

struct ObjectTypeInformation {
    UnicodeString type_name;
    uint total_number_of_objects;
    uint total_number_of_handles;
    uint total_paged_pool_usage;
    uint total_non_paged_pool_usage;
    uint total_name_pool_usage;
    uint total_handle_table_usage;
    uint high_water_number_of_objects;
    uint high_water_number_of_handles;
    uint high_water_paged_pool_usage;
    uint high_water_non_paged_pool_usage;
    uint high_water_name_pool_usage;
    uint high_water_handle_table_usage;
    uint invalid_attributes;
    GenericMapping generic_mapping;
    uint valid_access_mask;
    char security_required;
    char maintain_handle_count;
    char type_index;
    char reserved_byte;
    uint pool_type;
    uint default_paged_pool_charge;
    uint default_non_paged_pool_charge;
}

struct ObjectTypesInformation {
    uint number_of_types;
}

struct ObjectAttributes {
    uint length;
    void* root_directory;
    UnicodeString* object_name;
    uint attributes;
    void* security_descriptor;
    void* security_quality_of_service;
}

// enums

enum ObjectInformationClass {
    OBJECT_BASIC_INFORMATION,
    OBJECT_NAME_INFORMATION,
    OBJECT_TYPE_INFORMATION,
    OBJECT_TYPES_INFORMATION,
    OBJECT_HANDLE_FLAG_INFORMATION,
    OBJECT_SESSION_INFORMATION,
    OBJECT_SESSION_OBJECT_INFORMATION,
    OBJECT_SET_REF_TRACE_INFORMATION,
    MAX_OBJECT_INFO_CLASS
}
