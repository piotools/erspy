module ntapi @if (env::WIN32);

const uint IMAGE_DOS_SIGNATURE = 0x00005A4D;
const uint IMAGE_NT_SIGNATURE = 0x00004550;

const uint IMAGE_NUMBEROF_DIRECTORY_ENTRIES = 16;
const uint IMAGE_SIZEOF_SHORT_NAME = 8;

struct ImageDosHeader {
    ushort e_magic;
    ushort e_cblp;
    ushort e_cp;
    ushort e_crlc;
    ushort e_cparhdr;
    ushort e_minalloc;
    ushort e_maxalloc;
    ushort e_ss;
    ushort e_sp;
    ushort e_csum;
    ushort e_ip;
    ushort e_cs;
    ushort e_lfarlc;
    ushort e_ovno;
    ushort[4] e_res;
    ushort e_oemid;
    ushort e_oeminfo;
    ushort[10] e_res2;
    int e_lfanew;
}

struct ImageFileHeader {
    ushort machine;
    ushort number_of_sections;
    uint time_date_stamp;
    uint pointer_to_symbol_table;
    uint number_of_symbols;
    ushort size_of_optional_header;
    ushort characteristics;
}

struct ImageDataDirectory {
    uint virtual_address;
    uint size;
}

struct ImageOptionalHeader64 {
    ushort magic;
    char major_linker_version;
    char minor_linker_version;
    uint size_of_code;
    uint size_of_initialized_data;
    uint size_of_uninitialized_data;
    uint address_of_entry_point;
    uint base_of_code;
    ulong image_base;
    uint section_alignment;
    uint file_alignment;
    ushort major_operating_system_version;
    ushort minor_operating_system_version;
    ushort major_image_version;
    ushort minor_image_version;
    ushort major_subsystem_version;
    ushort minor_subsystem_version;
    uint win32_version_value;
    uint size_of_image;
    uint size_of_headers;
    uint check_sum;
    ushort subsystem;
    ushort dll_characteristics;
    ulong size_of_stack_reserve;
    ulong size_of_stack_commit;
    ulong size_of_heap_reserve;
    ulong size_of_heap_commit;
    uint loader_flags;
    uint number_of_rva_and_sizes;
    ImageDataDirectory[IMAGE_NUMBEROF_DIRECTORY_ENTRIES] data_directory;
}

struct ImageNtHeaders64 {
    uint signature;
    ImageFileHeader file_header;
    ImageOptionalHeader64 optional_header;
}

struct ImageExportDirectory {
    uint characteristics;
    uint time_date_stamp;
    ushort major_version;
    ushort minor_version;
    uint name;
    uint base;
    uint number_of_functions;
    uint number_of_names;
    uint address_of_functions;
    uint address_of_names;
    uint address_of_name_ordinals;
}
