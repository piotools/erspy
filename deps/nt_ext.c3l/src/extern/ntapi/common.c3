module ntapi @if (env::WIN32);

// constants

const uint STATUS_INFO_LENGTH_MISMATCH = 0xC0000004;
const uint STATUS_TIMEOUT = 0x00000102;

// macros

macro bool success(status) => status >= 0;
macro bool failure(status) => status < 0;

macro containing_record(address, $Type, $field) {
    return ($Type*)((uptr)address - $Type.$eval($field).offsetof);
}

// structs

struct ClientId {
    void* unique_process;
    void* unique_thread;
}

struct ListEntry {
    ListEntry* flink;
    ListEntry* blink;
}

struct UnicodeString {
    ushort length;
    ushort maximum_length;
    WString buffer;
}

struct NativeString {
    ushort length;
    ushort maximum_length;
    char* buffer;
}

struct GenericMapping {
    uint generic_read;
    uint generic_write;
    uint generic_execute;
    uint generic_all;
}

fn String? UnicodeString.to_string(&self, Allocator allocator = mem) @inline {
    WString buffer = (WString)self.buffer[:self.length];
    return string::from_wstring(allocator, buffer);
}

fn String? UnicodeString.tto_string(&self) @inline => self.to_string(tmem);

fn bool UnicodeString.eq_to_string(&self, String target) @operator(==) {
    uint len = self.length / 2;
    if (len != target.len) return false;

    for (usz i = 0; i < len; i++) {
        if ((char)self.buffer[i] != target[i]) return false;
    }

    return true;
}

// types

union LargeInteger {
    struct dummy {
        uint low_part;
        int high_part;
    }

    struct u {
        uint low_part;
        int high_part;
    }

    long quad_part;
}
