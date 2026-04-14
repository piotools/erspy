module ntapi @if (env::WIN32);

// constants

const uint RTL_MAX_DRIVE_LETTERS = 32;
const uint GDI_HANDLE_BUFFER_SIZE = 34;

// functions

extern fn int open_process(
    void** process_handle,
    uint access_mask,
    ObjectAttributes* object_attributes,
    ClientId* client_id
) @cname("NtOpenProcess");

extern fn int query_info_process(
    void* process_handle,
    ProcessInformationClass process_information_class,
    void* process_information,
    uint process_information_length,
    uint* return_length
) @cname("NtQueryInformationProcess");

// structs

struct ProcessBasicInformation {
    int exit_status;
    Peb* peb_base_address;
    ulong affinity;
    int base_priority;
    void* unique_process_id;
    void* inherited_from_unique_process_id;
}

struct Peb {
    char inherited_address_space;
    char read_image_file_exec_options;
    char being_debugged;

    union {
        char bit_field;
        bitstruct : char {
            bool image_uses_large_pages : 0;
            bool is_protected_process : 1;
            bool is_image_dynamically_relocated : 2;
            bool skip_patching_user32_forwarders : 3;
            bool is_packaged_process : 4;
            bool is_app_container_process : 5;
            bool is_protected_process_light : 6;
            bool is_long_path_aware_process : 7;
        }
    }

    void* mutant;
    void* image_base_address;
    PebLdrData* ldr;
    RtlUserProcessParameters* process_parameters;
    void* sub_system_data;
    void* process_heap;
    void* fast_peb_lock;
    void* atl_thunk_slist_ptr;
    void* ifeo_key;

    union {
        uint cross_process_flags;
        bitstruct : uint {
            uint process_in_job : 0..0;
            uint process_initializing : 1..1;
            uint process_using_veh : 2..2;
            uint process_using_vch : 3..3;
            uint process_using_fth : 4..4;
            uint process_previously_throttled : 5..5;
            uint process_currently_throttled : 6..6;
            uint process_images_hot_patched : 7..7;
            uint reserved_bits0 : 8..31;
        }
    }

    union {
        void* kernel_callback_table;
        void* user_shared_info_ptr;
    }

    uint system_reserved;
    uint atl_thunk_slist_ptr32;
    void* api_set_map;
    uint tls_expansion_counter;
    void* tls_bitmap;
    uint[2] tls_bitmap_bits;
    void* read_only_shared_memory_base;
    void* shared_data;
    void** read_only_static_server_data;
    void* ansi_code_page_data;
    void* oem_code_page_data;
    void* unicode_case_table_data;
    uint number_of_processors;

    union {
        uint nt_global_flag;
        bitstruct : uint {
            uint stop_on_exception : 0..0;
            uint show_loader_snaps : 1..1;
            uint debug_initial_command : 2..2;
            uint stop_on_hung_gui : 3..3;
            uint heap_enable_tail_check : 4..4;
            uint heap_enable_free_check : 5..5;
            uint heap_validate_parameters : 6..6;
            uint heap_validate_all : 7..7;
            uint application_verifier : 8..8;
            uint monitor_silent_process_exit : 9..9;
            uint pool_enable_tagging : 10..10;
            uint heap_enable_tagging : 11..11;
            uint user_stack_trace_db : 12..12;
            uint kernel_stack_trace_db : 13..13;
            uint maintain_object_type_list : 14..14;
            uint heap_enable_tag_by_dll : 15..15;
            uint disable_stack_extension : 16..16;
            uint enable_csr_debug : 17..17;
            uint enable_k_debug_symbol_load : 18..18;
            uint disable_page_kernel_stacks : 19..19;
            uint enable_system_crit_breaks : 20..20;
            uint heap_disable_coalescing : 21..21;
            uint enable_close_exceptions : 22..22;
            uint enable_exception_logging : 23..23;
            uint enable_handle_type_tagging : 24..24;
            uint heap_page_allocs : 25..25;
            uint debug_initial_command_ex : 26..26;
            uint disable_dbg_print : 27..27;
            uint crit_sec_event_creation : 28..28;
            uint ldr_top_down : 29..29;
            uint enable_handle_exceptions : 30..30;
            uint disable_prot_dlls : 31..31;
        }
    }

    long critical_section_timeout;
    isz heap_segment_reserve;
    isz heap_segment_commit;
    isz heap_de_commit_total_free_threshold;
    isz heap_de_commit_free_block_threshold;
    uint number_of_heaps;
    uint maximum_number_of_heaps;
    void** process_heaps;
    void* gdi_shared_handle_table;
    void* process_starter_helper;
    uint gdi_dc_attribute_list;
    void* loader_lock;
    uint os_major_version;
    uint os_minor_version;
    ushort os_build_number;
    ushort os_csd_version;
    uint os_platform_id;
    uint image_subsystem;
    uint image_subsystem_major_version;
    uint image_subsystem_minor_version;
    isz active_process_affinity_mask;
    uint[GDI_HANDLE_BUFFER_SIZE] gdi_handle_buffer;
    void* post_process_init_routine;
    void* tls_expansion_bitmap;
    uint[32] tls_expansion_bitmap_bits;
    uint session_id;
    ulong app_compat_flags;
    ulong app_compat_flags_user;
    void* p_shim_data;
    void* app_compat_info;
    UnicodeString csd_version;
    void* activation_context_data;
    void* process_assembly_storage_map;
    void* system_default_activation_context_data;
    void* system_assembly_storage_map;
    isz minimum_stack_commit;
    void*[2] spare_pointers;
    void* patch_loader_data;
    void* chpe_v2_process_info;
    uint app_model_feature_state;
    uint[2] spare_ulongs;
    ushort active_code_page;
    ushort oem_code_page;
    ushort use_case_mapping;
    ushort unused_nls_field;
    void* wer_registration_data;
    void* wer_ship_assert_ptr;

    union {
        void* p_context_data;
        void* ec_code_bit_map;
    }

    void* image_header_hash;

    union {
        uint tracing_flags;
        bitstruct : uint {
            uint heap_tracing_enabled : 0..0;
            uint crit_sec_tracing_enabled : 1..1;
            uint lib_loader_tracing_enabled : 2..2;
            uint spare_tracing_bits : 3..31;
        }
    }

    ulong csr_server_read_only_shared_memory_base;
    void* tpp_workerp_list_lock;
    ListEntry tpp_workerp_list;
    void*[128] wait_on_address_hash_table;
    void* telemetry_coverage_header;
    uint cloud_file_flags;
    uint cloud_file_diag_flags;
    char placeholder_compatibility_mode;
    char[7] placeholder_compatibility_mode_reserved;
    void* leap_second_data;

    union {
        uint leap_second_flags;
        bitstruct : uint {
            uint sixty_second_enabled : 0..0;
            uint reserved : 1..31;
        }
    }

    uint nt_global_flag2;
    ulong extended_feature_disable_mask;
}

struct PebLdrData {
    uint length;
    char initialized;
    void* ss_handle;
    ListEntry in_load_order_module_list;
    ListEntry in_memory_order_module_list;
    ListEntry in_initialization_order_module_list;
    void* entry_in_progress;
    char shutdown_in_progress;
    void* shutdown_thread_id;
}

struct RtlUserProcessParameters {
    uint maximum_length;
    uint length;
    uint flags;
    uint debug_flags;
    void* console_handle;
    uint console_flags;
    void* standard_input;
    void* standard_output;
    void* standard_error;
    CurDir current_directory;
    UnicodeString dll_path;
    UnicodeString image_path_name;
    UnicodeString command_line;
    void* environment;
    uint starting_x;
    uint starting_y;
    uint count_x;
    uint count_y;
    uint count_chars_x;
    uint count_chars_y;
    uint fill_attribute;
    uint window_flags;
    uint show_window_flags;
    UnicodeString window_title;
    UnicodeString desktop_info;
    UnicodeString shell_info;
    UnicodeString runtime_data;
    RtlDriveLetterCurDir[RTL_MAX_DRIVE_LETTERS] current_directories;
    uptr environment_size;
    uptr environment_version;
    void* package_dependency_data;
    uint process_group_id;
    uint loader_threads;
    UnicodeString redirection_dll_name;
    UnicodeString heap_partition_name;
    ulong* default_threadpool_cpu_set_masks;
    uint default_threadpool_cpu_set_mask_count;
    uint default_threadpool_thread_maximum;
    uint heap_memory_type_mask;
}

struct CurDir {
    UnicodeString dos_path;
    void* handle;
}

struct RtlDriveLetterCurDir {
    ushort flags;
    ushort length;
    uint time_stamp;
    NativeString dos_path;
}

// enums

enum ProcessInformationClass {
    PROCESS_BASIC_INFORMATION,
    PROCESS_QUOTA_LIMITS,
    PROCESS_IO_COUNTERS,
    PROCESS_VM_COUNTERS,
    PROCESS_TIMES,
    PROCESS_BASE_PRIORITY,
    PROCESS_RAISE_PRIORITY,
    PROCESS_DEBUG_PORT,
    PROCESS_EXCEPTION_PORT,
    PROCESS_ACCESS_TOKEN,
    PROCESS_LDT_INFORMATION,
    PROCESS_LDT_SIZE,
    PROCESS_DEFAULT_HARD_ERROR_MODE,
    PROCESS_IO_PORT_HANDLERS,
    PROCESS_POOLED_USAGE_AND_LIMITS,
    PROCESS_WORKING_SET_WATCH,
    PROCESS_USER_MODE_IOPL,
    PROCESS_ENABLE_ALIGNMENT_FAULT_FIXUP,
    PROCESS_PRIORITY_CLASS,
    PROCESS_WX86_INFORMATION,
    PROCESS_HANDLE_COUNT,
    PROCESS_AFFINITY_MASK,
    PROCESS_PRIORITY_BOOST,
    PROCESS_DEVICE_MAP,
    PROCESS_SESSION_INFORMATION,
    PROCESS_FOREGROUND_INFORMATION,
    PROCESS_WOW64_INFORMATION,
    PROCESS_IMAGE_FILE_NAME,
    PROCESS_LUID_DEVICE_MAPS_ENABLED,
    PROCESS_BREAK_ON_TERMINATION,
    PROCESS_DEBUG_OBJECT_HANDLE,
    PROCESS_DEBUG_FLAGS,
    PROCESS_HANDLE_TRACING,
    PROCESS_IO_PRIORITY,
    PROCESS_EXECUTE_FLAGS,
    PROCESS_TLS_INFORMATION,
    PROCESS_COOKIE,
    PROCESS_IMAGE_INFORMATION,
    PROCESS_CYCLE_TIME,
    PROCESS_PAGE_PRIORITY,
    PROCESS_INSTRUMENTATION_CALLBACK,
    PROCESS_THREAD_STACK_ALLOCATION,
    PROCESS_WORKING_SET_WATCH_EX,
    PROCESS_IMAGE_FILE_NAME_WIN32,
    PROCESS_IMAGE_FILE_MAPPING,
    PROCESS_AFFINITY_UPDATE_MODE,
    PROCESS_MEMORY_ALLOCATION_MODE,
    PROCESS_GROUP_INFORMATION,
    PROCESS_TOKEN_VIRTUALIZATION_ENABLED,
    PROCESS_CONSOLE_HOST_PROCESS,
    PROCESS_WINDOW_INFORMATION,
    PROCESS_HANDLE_INFORMATION,
    PROCESS_MITIGATION_POLICY,
    PROCESS_DYNAMIC_FUNCTION_TABLE_INFORMATION,
    PROCESS_HANDLE_CHECKING_MODE,
    PROCESS_KEEP_ALIVE_COUNT,
    PROCESS_REVOKE_FILE_HANDLES,
    PROCESS_WORKING_SET_CONTROL,
    PROCESS_HANDLE_TABLE,
    PROCESS_CHECK_STACK_EXTENTS_MODE,
    PROCESS_COMMAND_LINE_INFORMATION,
    PROCESS_PROTECTION_INFORMATION,
    PROCESS_MEMORY_EXHAUSTION,
    PROCESS_FAULT_INFORMATION,
    PROCESS_TELEMETRY_ID_INFORMATION,
    PROCESS_COMMIT_RELEASE_INFORMATION,
    PROCESS_DEFAULT_CPU_SETS_INFORMATION,
    PROCESS_ALLOWED_CPU_SETS_INFORMATION,
    PROCESS_SUBSYSTEM_PROCESS,
    PROCESS_JOB_MEMORY_INFORMATION,
    PROCESS_IN_PRIVATE,
    PROCESS_RAISE_UM_EXCEPTION_ON_INVALID_HANDLE_CLOSE,
    PROCESS_IUM_CHALLENGE_RESPONSE,
    PROCESS_CHILD_PROCESS_INFORMATION,
    PROCESS_HIGH_GRAPHICS_PRIORITY_INFORMATION,
    PROCESS_SUBSYSTEM_INFORMATION,
    PROCESS_ENERGY_VALUES,
    PROCESS_POWER_THROTTLING_STATE,
    PROCESS_ACTIVITY_THROTTLE_POLICY,
    PROCESS_WIN32K_SYSCALL_FILTER_INFORMATION,
    PROCESS_DISABLE_SYSTEM_ALLOWED_CPU_SETS,
    PROCESS_WAKE_INFORMATION,
    PROCESS_ENERGY_TRACKING_STATE,
    PROCESS_MANAGE_WRITES_TO_EXECUTABLE_MEMORY,
    PROCESS_CAPTURE_TRUSTLET_LIVE_DUMP,
    PROCESS_TELEMETRY_COVERAGE,
    PROCESS_ENCLAVE_INFORMATION,
    PROCESS_ENABLE_READ_WRITE_VM_LOGGING,
    PROCESS_UPTIME_INFORMATION,
    PROCESS_IMAGE_SECTION,
    PROCESS_DEBUG_AUTH_INFORMATION,
    PROCESS_SYSTEM_RESOURCE_MANAGEMENT,
    PROCESS_SEQUENCE_NUMBER,
    PROCESS_LOADER_DETOUR,
    PROCESS_SECURITY_DOMAIN_INFORMATION,
    PROCESS_COMBINE_SECURITY_DOMAINS_INFORMATION,
    PROCESS_ENABLE_LOGGING,
    PROCESS_LEAP_SECOND_INFORMATION,
    PROCESS_FIBER_SHADOW_STACK_ALLOCATION,
    PROCESS_FREE_FIBER_SHADOW_STACK_ALLOCATION,
    PROCESS_ALT_SYSTEM_CALL_INFORMATION,
    PROCESS_DYNAMIC_EH_CONTINUATION_TARGETS,
    PROCESS_DYNAMIC_ENFORCED_CET_COMPATIBLE_RANGES,
    PROCESS_CREATE_STATE_CHANGE,
    PROCESS_APPLY_STATE_CHANGE,
    PROCESS_ENABLE_OPTIONAL_X_STATE_FEATURES,
    PROCESS_ALT_PREFETCH_PARAM,
    PROCESS_ASSIGN_CPU_PARTITIONS,
    PROCESS_PRIORITY_CLASS_EX,
    PROCESS_MEMBERSHIP_INFORMATION,
    PROCESS_EFFECTIVE_IO_PRIORITY,
    PROCESS_EFFECTIVE_PAGE_PRIORITY,
    PROCESS_SCHEDULER_SHARED_DATA,
    PROCESS_SLIST_ROLLBACK_INFORMATION,
    PROCESS_NETWORK_IO_COUNTERS,
    PROCESS_FIND_FIRST_THREAD_BY_TEB_VALUE,
    PROCESS_ENCLAVE_ADDRESS_SPACE_RESTRICTION,
    PROCESS_AVAILABLE_CPUS,
    MAX_PROCESS_INFO_CLASS
}
