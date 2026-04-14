module ntapi @if (env::WIN32);

// functions

fn Peb* get_peb() @naked @noinline {
    asm (
        "movq %gs:0x60, %rax\n"
        "ret"
    );
}

fn void* get_module_base(String module_name) {
    PebLdrData* ldr = get_peb().ldr;
    ListEntry* list_head = &ldr.in_memory_order_module_list;
    ListEntry* current = list_head.flink;

    while (current != list_head) {
        LdrDataTableEntry* entry = ntapi::containing_record(current, LdrDataTableEntry, "in_memory_order_links");
        if (entry.base_dll_name.buffer && entry.base_dll_name == module_name) {
            return entry.dll_base;
        }

        current = entry.in_memory_order_links.flink;
    }

    return null;
}

fn void* get_proc_address(void* mod, String func_name) {
    if (!mod) return null;

    uptr base = (uptr)mod;

    ImageDosHeader* dos_header = (ImageDosHeader*)mod;
    if (dos_header.e_magic != ntapi::IMAGE_DOS_SIGNATURE) return null;

    ImageNtHeaders64* nt_headers = (ImageNtHeaders64*)(base + dos_header.e_lfanew);
    if (nt_headers.signature != ntapi::IMAGE_NT_SIGNATURE) return null;

    ImageDataDirectory export_dir = nt_headers.optional_header.data_directory[0];
    if (export_dir.virtual_address == 0 || export_dir.size == 0) return null;

    ImageExportDirectory* exports = (ImageExportDirectory*)(base + export_dir.virtual_address);
    if (!exports) return null;

    uint* name_table = (uint*)(base + exports.address_of_names);
    uint* func_table = (uint*)(base + exports.address_of_functions);
    ushort* ordinal_table = (ushort*)(base + exports.address_of_name_ordinals);

    for (uint i = 0; i < exports.number_of_names; i++) {
        ZString current_name = (ZString)(base + name_table[i]);
        if (current_name == (ZString)func_name.ptr) {
            ushort ordinal = ordinal_table[i];
            uint func_rva = func_table[ordinal];
            return (void*)(base + func_rva);
        }
    }

    return null;
}

// structs

struct RtlBalancedNode {
    union {
        RtlBalancedNode*[2] children;
        struct {
            RtlBalancedNode* left;
            RtlBalancedNode* right;
        }
    }

    union {
        bitstruct : uptr {
            char red : 0..0;
            char balance : 1..2;
        }
        uptr parent_value;
    }
}

struct LdrDataTableEntry {
    ListEntry in_load_order_links;
    ListEntry in_memory_order_links;
    ListEntry in_initialization_order_links;
    void* dll_base;
    void* entry_point;
    uint size_of_image;
    UnicodeString full_dll_name;
    UnicodeString base_dll_name;

    union {
        char[4] flag_group;
        uint flags;

        bitstruct : uint {
            uint packaged_binary : 0..0;
            uint marked_for_removal : 1..1;
            uint image_dll : 2..2;
            uint load_notifications_sent : 3..3;
            uint telemetry_entry_processed : 4..4;
            uint process_static_import : 5..5;
            uint in_legacy_lists : 6..6;
            uint in_indexes : 7..7;
            uint shim_dll : 8..8;
            uint in_exception_table : 9..9;
            uint verifier_provider : 10..10;
            uint shim_engine_callout_sent : 11..11;
            uint load_in_progress : 12..12;
            uint load_config_processed : 13..13;
            uint entry_processed : 14..14;
            uint protect_delay_load : 15..15;
            uint aux_iat_copy_private : 16..16;
            uint reserved_flags3 : 17..17;
            uint dont_call_for_threads : 18..18;
            uint process_attach_called : 19..19;
            uint process_attach_failed : 20..20;
            uint scp_in_exception_table : 21..21;
            uint cor_image : 22..22;
            uint dont_relocate : 23..23;
            uint cor_il_only : 24..24;
            uint chpe_image : 25..25;
            uint chpe_emulator_image : 26..26;
            uint reserved_flags5 : 27..27;
            uint redirected : 28..28;
            uint reserved_flags6 : 29..30;
            uint compat_database_processed : 31..31;
        }
    }

    ushort obsolete_load_count;
    ushort tls_index;
    ListEntry hash_links;
    uint time_date_stamp;
    void* entry_point_activation_context;
    void* lock;
    void* ddag_node;
    ListEntry node_module_link;
    void* load_context;
    void* parent_dll_base;
    void* switch_back_context;
    RtlBalancedNode base_address_index_node;
    RtlBalancedNode mapping_info_index_node;
    void* original_base;
    long load_time;
    uint base_name_hash_value;
    LdrDllLoadReason load_reason;
    uint implicit_path_options;
    uint reference_count;
    uint dependent_load_flags;
    char signing_level;
    uint check_sum;
    void* active_patch_image_base;
    LdrHotPatchState hot_patch_state;
}

// enums

enum LdrDllLoadReason : const CInt {
    UNKNOWN = -1,
    STATIC_DEPENDENCY = 0,
    STATIC_FORWARDER_DEPENDENCY = 1,
    DYNAMIC_FORWARDER_DEPENDENCY = 2,
    DELAYLOAD_DEPENDENCY = 3,
    DYNAMIC_LOAD = 4,
    AS_IMAGE_LOAD = 5,
    AS_DATA_LOAD = 6,
    ENCLAVE_PRIMARY = 7,
    ENCLAVE_DEPENDENCY = 8,
    PATCH_IMAGE = 9
}

enum LdrHotPatchState {
    BASE_IMAGE,
    NOT_APPLIED,
    APPLIED_REVERSE,
    APPLIED_FORWARD,
    FAILED_TO_PATCH,
    STATE_MAX
}
